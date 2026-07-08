import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class MjpegStreamView extends StatefulWidget {
  final String streamUrl;
  final double? height;
  final BoxFit fit;

  const MjpegStreamView({
    super.key,
    required this.streamUrl,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<MjpegStreamView> createState() => _MjpegStreamViewState();
}

class _MjpegStreamViewState extends State<MjpegStreamView> {
  Uint8List? _currentFrame;
  StreamSubscription? _subscription;
  http.Client? _client;
  bool _isConnecting = true;
  String? _error;

  static const _jpegStart = [0xFF, 0xD8];
  static const _jpegEnd = [0xFF, 0xD9];

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      _client = http.Client();
      final request = http.Request('GET', Uri.parse(widget.streamUrl));
      final response = await _client!.send(request);

      if (response.statusCode != 200) {
        throw Exception('Stream error: ${response.statusCode}');
      }

      List<int> buffer = [];

      _subscription = response.stream.listen(
        (chunk) {
          buffer.addAll(chunk);

          final startIndex = _findMarker(buffer, _jpegStart);
          final endIndex = _findMarker(
            buffer,
            _jpegEnd,
            startIndex >= 0 ? startIndex + 2 : 0,
          );

          if (startIndex >= 0 && endIndex >= 0 && endIndex > startIndex) {
            final frameBytes = buffer.sublist(startIndex, endIndex + 2);
            if (mounted) {
              setState(() {
                _currentFrame = Uint8List.fromList(frameBytes);
                _isConnecting = false;
              });
            }
            buffer = buffer.sublist(endIndex + 2);
          }

          if (buffer.length > 2000000) buffer.clear();
        },
        onError: (e) {
          if (mounted) {
            setState(() {
              _error = "Camera connection lost";
              _isConnecting = false;
            });
          }
        },
        onDone: () {
          if (mounted) setState(() => _error = "Stream stopped");
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              "Failed to connect to the camera. Check backend IP and Wi-Fi.";
          _isConnecting = false;
        });
      }
    }
  }

  int _findMarker(List<int> data, List<int> marker, [int start = 0]) {
    for (int i = start; i <= data.length - marker.length; i++) {
      bool found = true;
      for (int j = 0; j < marker.length; j++) {
        if (data[i + j] != marker[j]) {
          found = false;
          break;
        }
      }
      if (found) return i;
    }
    return -1;
  }

  void _retry() {
    _subscription?.cancel();
    _client?.close();
    _connect();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final live = _error == null && !_isConnecting && _currentFrame != null;

    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildContent(),
            // Viewfinder grid overlay, only when actively streaming
            if (live)
              IgnorePointer(child: CustomPaint(painter: _ViewfinderPainter())),
            if (live) _buildLiveBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Positioned(
      top: 12,
      left: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFFF453A),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "LIVE",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.videocam_off_rounded,
              color: Colors.redAccent.withOpacity(0.85),
              size: 40,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _error!,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 13.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _retry,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.08),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(
                Icons.refresh_rounded,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                "Try Again",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_isConnecting || _currentFrame == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: Colors.greenAccent,
              strokeWidth: 2.4,
            ),
            const SizedBox(height: 12),
            Text(
              "Connecting to camera…",
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      );
    }

    return Image.memory(
      _currentFrame!,
      gaplessPlayback: true,
      fit: widget.fit,
      width: double.infinity,
    );
  }
}

/// Draws a subtle rule-of-thirds grid plus iOS-camera-style corner
/// brackets so the feed visually reads as a live camera viewfinder.
class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.16)
      ..strokeWidth = 0.8;

    final w = size.width;
    final h = size.height;

    // Rule of thirds grid
    for (int i = 1; i < 3; i++) {
      final x = w / 3 * i;
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
      final y = h / 3 * i;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // Corner brackets
    final bracketPaint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    const len = 22.0;
    const inset = 14.0;

    void corner(Offset origin, Offset dx, Offset dy) {
      canvas.drawLine(origin, origin + dx, bracketPaint);
      canvas.drawLine(origin, origin + dy, bracketPaint);
    }

    // Top-left
    corner(
      const Offset(inset, inset),
      const Offset(len, 0),
      const Offset(0, len),
    );
    // Top-right
    corner(
      Offset(w - inset, inset),
      const Offset(-len, 0),
      const Offset(0, len),
    );
    // Bottom-left
    corner(
      Offset(inset, h - inset),
      const Offset(len, 0),
      const Offset(0, -len),
    );
    // Bottom-right
    corner(
      Offset(w - inset, h - inset),
      const Offset(-len, 0),
      const Offset(0, -len),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
