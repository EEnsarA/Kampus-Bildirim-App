import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kampus_bildirim/components/map_notification_card.dart';
import 'package:kampus_bildirim/models/app_notification.dart';
import 'package:kampus_bildirim/providers/notification_provider.dart';
import 'package:kampus_bildirim/services/location_service.dart';

class MapPage extends ConsumerStatefulWidget {
  final AppNotification? focusNotification;
  const MapPage({super.key, this.focusNotification});

  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  GoogleMapController? _mapController;
  AppNotification? _selectedNotification;
  LatLng? _lastUserPosition;

  static const _initialPosition = CameraPosition(
    target: LatLng(39.9055, 41.2658), // Erzurum
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _goToUserLocation() async {
    LatLng targetPos;
    if (_lastUserPosition != null) {
      targetPos = _lastUserPosition!;
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: targetPos, zoom: 15),
        ),
      );
    } else {
      try {
        final position = await LocationService.getCurrentLocation();
        targetPos = LatLng(position.latitude, position.longitude);
        _lastUserPosition = targetPos;

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: targetPos, zoom: 15),
          ),
        );
      } catch (e) {
        // Konum alınamazsa sessiz kalabilir veya toast gösterebiliriz
        debugPrint("Konuma gidilemedi: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      body: Stack(
        children: [
          notificationsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text("Hata : $err")),
            data: (notifications) {
              final Set<Marker> markers =
                  notifications.map((notification) {
                    return Marker(
                      markerId: MarkerId(notification.id),
                      position: LatLng(
                        notification.latitude,
                        notification.longitude,
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        notification.markerHue,
                      ),
                      onTap: () {
                        setState(() {
                          _selectedNotification = notification;
                        });
                      },
                    );
                  }).toSet();

              return GoogleMap(
                initialCameraPosition: _initialPosition,
                markers: markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Eğer belirli bir bildirime odaklanmak istiyorsak
                  if (widget.focusNotification != null) {
                    final notification = widget.focusNotification!;
                    _mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(
                            notification.latitude,
                            notification.longitude,
                          ),
                          zoom: 17,
                        ),
                      ),
                    );
                    setState(() {
                      _selectedNotification = notification;
                    });
                  }
                  // Ana sayfadan açıldığında varsayılan konumda kalır
                },
                onTap: (_) {
                  setState(() {
                    _selectedNotification = null;
                  });
                },
              );
            },
          ),
          Positioned(
            top: 50,
            left: 16,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            bottom: _selectedNotification != null ? 220 : 30,
            right: 16,
            child: FloatingActionButton(
              heroTag: "map_loc",
              backgroundColor: Colors.white,
              onPressed: _goToUserLocation,
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),

          if (_selectedNotification != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: MapNotificationCard(
                notification: _selectedNotification!,
                onDetailPressed: () {
                  context.push(
                    '/notification-detail/${_selectedNotification!.id}',
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
