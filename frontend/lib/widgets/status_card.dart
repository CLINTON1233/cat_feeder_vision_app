import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusCard extends StatelessWidget {
  final String statusText;
  final bool isConnected;

  const StatusCard({
    super.key,
    required this.statusText,
    required this.isConnected,
  });

  bool get _catDetected =>
      statusText.toUpperCase().contains("CAT") ||
      statusText.toUpperCase().contains("DETECTED");

  Color get _accentColor {
    if (!isConnected) return const Color(0xFFFF453A); // iOS red
    if (_catDetected) return const Color(0xFF30D158); // iOS green
    return const Color(0xFFFF9F0A); // iOS orange
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          width: double.infinity,
          padding: EdgeInsets.all(isTablet ? 22 : 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _accentColor.withOpacity(0.45), width: 1),
            boxShadow: [
              BoxShadow(
                color: _accentColor.withOpacity(0.12),
                blurRadius: 24,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: isTablet ? 52 : 44,
                height: isTablet ? 52 : 44,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected
                      ? (_catDetected
                            ? Icons.pets_rounded
                            : Icons.podcasts_rounded)
                      : Icons.wifi_off_rounded,
                  color: _accentColor,
                  size: isTablet ? 26 : 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConnected ? "ESP32 · MQTT" : "Disconnected",
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: isTablet ? 13 : 11.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: isTablet ? 19 : 16,
                        letterSpacing: -0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _accentColor,
                  boxShadow: [
                    BoxShadow(
                      color: _accentColor.withOpacity(0.7),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
