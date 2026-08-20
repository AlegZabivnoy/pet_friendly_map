import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationHelper {
  static void openNavigationSheet(BuildContext context, LatLng destination) {
    final lat = destination.latitude;
    final lng = destination.longitude;

    final Uri appleMapsUrl = Uri.parse('https://maps.apple.com/?daddr=$lat,$lng');
    final Uri googleMapsUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    final Uri wazeUrl = Uri.parse('https://waze.com/ul?ll=$lat,$lng&navigate=yes');

    Future<void> launchMapUrl(Uri url) async {
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Не удалось открыть приложение карт')),
          );
        }
      }
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? Colors.grey[900]! : Colors.white;

        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.map_outlined, color: Colors.blueAccent),
                  title: const Text('Apple Maps', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    launchMapUrl(appleMapsUrl);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.pin_drop, color: Colors.redAccent),
                  title: const Text('Google Maps', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    launchMapUrl(googleMapsUrl);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.navigation_outlined, color: Colors.cyan),
                  title: const Text('Waze', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(ctx);
                    launchMapUrl(wazeUrl);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}