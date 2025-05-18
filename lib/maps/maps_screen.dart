import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:WanderBite/core/constants/app_constants.dart';
import 'package:WanderBite/auth/services/notification_service.dart';
import 'package:WanderBite/core/themes/theme_provider.dart';

/// Map screen using flutter_map and OpenStreetMap
class MapsScreen extends StatefulWidget {
  const MapsScreen({Key? key}) : super(key: key);

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  final List<MapMarker> _markers = [];
  bool _isLoading = false;
  final MapController _mapController = MapController();
  // Track the current map center
  LatLng _currentMapCenter =
      LatLng(40.7128, -74.0060); // Default to New York City
  // Current zoom level for the map
  double _currentZoom = 12.0;

  @override
  void initState() {
    super.initState();
    _addExampleMarkers();
  }

  void _addExampleMarkers() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final bool isTravelTheme =
        themeProvider.themeType == AppConstants.travelTheme;

    setState(() {
      _markers.clear();
      if (isTravelTheme) {
        // Example travel points of interest
        _markers.add(
          MapMarker(
            id: 'poi_1',
            title: 'Tourist Attraction',
            description: 'A popular tourist spot',
            color: Colors.green,
            position: LatLng(40.7128, -74.0060),
          ),
        );
        _markers.add(
          MapMarker(
            id: 'poi_2',
            title: 'Historical Site',
            description: 'A place with historical significance',
            color: Colors.purple,
            position: LatLng(40.7589, -73.9851),
          ),
        );
      } else {
        // Example restaurant/recipe related points
        _markers.add(
          MapMarker(
            id: 'restaurant_1',
            title: 'Italian Restaurant',
            description: 'Authentic Italian cuisine',
            color: Colors.red,
            position: LatLng(40.7306, -73.9352),
          ),
        );
        _markers.add(
          MapMarker(
            id: 'market_1',
            title: 'Farmers Market',
            description: 'Fresh local ingredients',
            color: Colors.orange,
            position: LatLng(40.7420, -74.0080),
          ),
        );
      }
    });
  }

  void _showAddMarkerDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Marker'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
              ),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.isEmpty) {
                return;
              }

              setState(() {
                final newMarker = MapMarker(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  title: titleController.text,
                  description: descriptionController.text,
                  color: Colors.blue,
                  position: _currentMapCenter,
                );
                _markers.add(newMarker);
                // Trigger notification
                Provider.of<NotificationService>(context, listen: false)
                    .notifyMapAction('Marker added: ${newMarker.title}');
              });

              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  List<Marker> _buildMarkers() {
    return _markers.map((marker) {
      return Marker(
        width: 40.0,
        height: 40.0,
        point: marker.position,
        child: GestureDetector(
          onTap: () {
            // Show marker details and trigger notification
            Provider.of<NotificationService>(context, listen: false)
                .notifyMapAction('Marker viewed: ${marker.title}');
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(marker.title),
                content: Text(marker.description),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
          child: Icon(
            Icons.location_pin,
            color: marker.color,
            size: 40,
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isTravelTheme =
        themeProvider.themeType == AppConstants.travelTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTravelTheme ? 'Travel Map' : 'Food Locations',
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentMapCenter,
              initialZoom: _currentZoom,
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  setState(() {
                    _currentMapCenter = event.camera.center;
                    _currentZoom = event.camera.zoom;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.wanderbite',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: _buildMarkers(),
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () => print('Attribution tapped'),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 200,
              color: Colors.white.withOpacity(0.9),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Map Markers',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _markers.length,
                      itemBuilder: (context, index) {
                        final marker = _markers[index];
                        return ListTile(
                          leading: Icon(
                            Icons.location_on,
                            color: marker.color,
                          ),
                          title: Text(marker.title),
                          subtitle: Text(marker.description),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                _markers.removeAt(index);
                                // Trigger notification
                                Provider.of<NotificationService>(context,
                                        listen: false)
                                    .notifyMapAction(
                                        'Marker deleted: ${marker.title}');
                              });
                            },
                          ),
                          onTap: () {
                            // Zoom to marker and trigger notification
                            _mapController.move(marker.position, 15.0);
                            Provider.of<NotificationService>(context,
                                    listen: false)
                                .notifyMapAction(
                                    'Zoomed to marker: ${marker.title}');
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          Positioned(
            bottom: 210.0,
            right: 16.0,
            child: FloatingActionButton(
              heroTag: 'add_marker',
              onPressed: _showAddMarkerDialog,
              child: const Icon(Icons.add_location),
            ),
          ),
          Positioned(
            top: 16.0,
            right: 16.0,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  onPressed: () {
                    final newZoom = _currentZoom + 1;
                    _mapController.move(_currentMapCenter, newZoom);
                    setState(() {
                      _currentZoom = newZoom;
                    });
                    // Trigger notification
                    Provider.of<NotificationService>(context, listen: false)
                        .notifyMapAction('Zoomed in to level $newZoom');
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  onPressed: () {
                    final newZoom = _currentZoom - 1;
                    if (newZoom > 0) {
                      _mapController.move(_currentMapCenter, newZoom);
                      setState(() {
                        _currentZoom = newZoom;
                      });
                      // Trigger notification
                      Provider.of<NotificationService>(context, listen: false)
                          .notifyMapAction('Zoomed out to level $newZoom');
                    }
                  },
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'my_location',
                  mini: true,
                  onPressed: () {
                    final newCenter = LatLng(40.7128, -74.0060);
                    _mapController.move(newCenter, 12.0);
                    setState(() {
                      _currentMapCenter = newCenter;
                      _currentZoom = 12.0;
                    });
                    // Trigger notification
                    Provider.of<NotificationService>(context, listen: false)
                        .notifyMapAction(
                            'Moved to default location: New York City');
                  },
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}

/// Custom marker class to store additional information for each map point
class MapMarker {
  final String id;
  final String title;
  final String description;
  final Color color;
  final LatLng position;

  MapMarker({
    required this.id,
    required this.title,
    required this.description,
    required this.color,
    required this.position,
  });
}
