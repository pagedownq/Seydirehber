import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import '../constants/app_colors.dart';

class InteractiveMapWidget extends StatelessWidget {
  final LatLng position;
  final String title;

  const InteractiveMapWidget({
    super.key,
    required this.position,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if the device has high pixel density (retina)
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Map Container
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          clipBehavior: Clip.antiAlias,
          child: RepaintBoundary(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: position,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.seydirehberim.app',
                  tileDisplay: const TileDisplay.instantaneous(),
                  tileProvider: CancellableNetworkTileProvider(),
                  retinaMode: devicePixelRatio > 1.0,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: position,
                      width: 120,
                      height: 85,
                      alignment: Alignment.topCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryDark,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              title.length > 20 ? '${title.substring(0, 17)}...' : title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.location_on_rounded,
                            color: Colors.red,
                            size: 40,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
