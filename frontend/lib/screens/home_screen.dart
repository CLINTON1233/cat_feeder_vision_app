import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_config.dart';
import '../service/api_service.dart';
import '../service/mqtt_service.dart';
import '../widgets/mjpeg_stream_view.dart';
import '../widgets/status_card.dart';
import '../widgets/manual_feed_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final MqttService _mqttService = MqttService();

  String _statusText = "Connecting...";
  bool _backendConnected = false;
  bool _isFeeding = false;

  Timer? _pollTimer;
  StreamSubscription? _mqttStatusSub;

  @override
  void initState() {
    super.initState();
    _initMqtt();
    _pollStatus();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _pollStatus(),
    );
  }

  Future<void> _initMqtt() async {
    await _mqttService.connect();
    _mqttStatusSub = _mqttService.statusStream.listen((payload) {
      if (mounted) {
        setState(() {
          _statusText = payload;
          _backendConnected = true;
        });
      }
    });
  }

  Future<void> _pollStatus() async {
    try {
      final status = await _apiService.getStatus();
      if (mounted) {
        setState(() {
          _statusText = status.cooldown;
          _backendConnected = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _backendConnected = false);
    }
  }

  Future<void> _handleManualFeed() async {
    setState(() => _isFeeding = true);
    try {
      final success = await _apiService.triggerManualFeed();
      if (mounted) {
        _showSnack(
          success ? "Feed command sent!" : "Failed to send command",
          success,
        );
      }
    } catch (e) {
      if (mounted) _showSnack("Error: $e", false);
    } finally {
      if (mounted) setState(() => _isFeeding = false);
    }
  }

  void _showSnack(String message, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(
              success ? Icons.check_circle_rounded : Icons.error_rounded,
              color: success
                  ? const Color(0xFF30D158)
                  : const Color(0xFFFF453A),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _mqttStatusSub?.cancel();
    _mqttService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWideScreen = size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _pollStatus,
          color: const Color(0xFF30D158),
          backgroundColor: const Color(0xFF1C1C1E),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: isWideScreen
                ? _buildWideLayout(size)
                : _buildNarrowLayout(size),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: AppBar(
            backgroundColor: const Color(0xFF0D0D0D).withOpacity(0.65),
            elevation: 0,
            centerTitle: false,
            titleSpacing: 16,
            title: Text(
              "Cat Feeder",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: (_backendConnected
                            ? const Color(0xFF30D158)
                            : const Color(0xFFFF453A))
                        .withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _backendConnected
                              ? const Color(0xFF30D158)
                              : const Color(0xFFFF453A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _backendConnected ? "Online" : "Offline",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _backendConnected
                              ? const Color(0xFF30D158)
                              : const Color(0xFFFF453A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.inter(
          color: Colors.white.withOpacity(0.38),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildNarrowLayout(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        _sectionLabel("Live Camera"),
        MjpegStreamView(
          streamUrl: AppConfig.videoStreamUrl,
          height: size.width * 9 / 16,
        ),
        const SizedBox(height: 24),
        _sectionLabel("Status"),
        StatusCard(statusText: _statusText, isConnected: _backendConnected),
        const SizedBox(height: 24),
        _sectionLabel("Controls"),
        ManualFeedButton(isLoading: _isFeeding, onPressed: _handleManualFeed),
      ],
    );
  }

  Widget _buildWideLayout(Size size) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _sectionLabel("Live Camera"),
              MjpegStreamView(
                streamUrl: AppConfig.videoStreamUrl,
                height: size.height * 0.6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _sectionLabel("Status"),
              StatusCard(
                statusText: _statusText,
                isConnected: _backendConnected,
              ),
              const SizedBox(height: 24),
              _sectionLabel("Controls"),
              ManualFeedButton(
                isLoading: _isFeeding,
                onPressed: _handleManualFeed,
              ),
            ],
          ),
        ),
      ],
    );
  }
}