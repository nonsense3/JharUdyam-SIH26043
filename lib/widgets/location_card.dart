import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jharudyam_citizen/constants/app_theme.dart';

class LocationCard extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String address;

  const LocationCard({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = latitude != 0.0 || longitude != 0.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasLocation)
            SizedBox(
              height: 160,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(latitude, longitude),
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(latitude, longitude),
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.location_on,
                          color: AppTheme.primaryColor,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                  ),
                ),
                if (hasLocation)
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 18, color: AppTheme.primaryColor),
                    onPressed: () {
                      final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
                      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                    },
                    tooltip: 'Open in Maps',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
