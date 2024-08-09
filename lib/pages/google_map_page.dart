import 'package:app/pages/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:app/keys.dart';
import 'calendar_screen.dart';
import 'notification_screen.dart';
import 'weather_app.dart';

class GoogleMapPage extends StatefulWidget {
  final String? eventLocation;

  const GoogleMapPage({Key? key, this.eventLocation}) : super(key: key);

  @override
  State<GoogleMapPage> createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  late GoogleMapController mapController;
  LatLng? _initialCameraPosition;
  List<LatLng> polylineCoordinates = [];
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  final TextEditingController _startLocationController =
      TextEditingController();
  final TextEditingController _endLocationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _endLocationController.text = widget.eventLocation ?? '';
  }

  @override
  void dispose() {
    _startLocationController.dispose();
    _endLocationController.dispose();
    super.dispose();
  }

  void _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    String currentAddress =
        await _getAddressFromCoordinates(position.latitude, position.longitude);

    setState(() {
      _startLocationController.text = currentAddress;
      _initialCameraPosition = LatLng(position.latitude, position.longitude);

      if (mapController != null) {
        _moveCameraToPosition(_initialCameraPosition!);
      }

      _addMarker(
        _initialCameraPosition!,
        "currentLocation",
        "You are here",
      );
    });
  }

  void _moveCameraToPosition(LatLng position) {
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: position,
          zoom: 15.0,
        ),
      ),
    );
  }

  Future<String> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        return '${placemark.street}, ${placemark.locality}, ${placemark.country}';
      }
    } catch (e) {
      print('Error getting address: $e');
    }
    return 'Address not found';
  }

  void _addMarker(LatLng position, String markerId, String? title) {
    markers.add(
      Marker(
        markerId: MarkerId(markerId),
        position: position,
        infoWindow: InfoWindow(title: title),
      ),
    );
  }

  void getRoute() async {
    String startLocation = _startLocationController.text;
    String endLocation = _endLocationController.text;

    try {
      List<Location> startPlacemark = await locationFromAddress(startLocation);
      List<Location> endPlacemark = await locationFromAddress(endLocation);

      double startLatitude = startPlacemark[0].latitude;
      double startLongitude = startPlacemark[0].longitude;
      double endLatitude = endPlacemark[0].latitude;
      double endLongitude = endPlacemark[0].longitude;

      PolylinePoints polylinePoints = PolylinePoints();

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        googleApiKey: googleAPiKey,
        request: PolylineRequest(
          origin: PointLatLng(startLatitude, startLongitude),
          destination: PointLatLng(endLatitude, endLongitude),
          mode: TravelMode.driving,
        ),
      );

      polylineCoordinates.clear();
      markers
          .removeWhere((marker) => marker.markerId.value != "currentLocation");
      polylines.clear();

      if (result.status == 'OK' && result.points.isNotEmpty) {
        for (var point in result.points) {
          polylineCoordinates.add(LatLng(point.latitude, point.longitude));
        }
      } else {
        print('Error getting route: ${result.errorMessage}');
        return;
      }

      _addMarker(polylineCoordinates.first, 'start', 'Start: $startLocation');
      _addMarker(polylineCoordinates.last, 'end', 'End: $endLocation');

      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylineCoordinates,
          color: Colors.blue,
          width: 5,
        ),
      );

      setState(() {});

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
            polylineCoordinates
                .reduce((value, element) =>
                    value.latitude < element.latitude ? value : element)
                .latitude,
            polylineCoordinates
                .reduce((value, element) =>
                    value.longitude < element.longitude ? value : element)
                .longitude),
        northeast: LatLng(
            polylineCoordinates
                .reduce((value, element) =>
                    value.latitude > element.latitude ? value : element)
                .latitude,
            polylineCoordinates
                .reduce((value, element) =>
                    value.longitude > element.longitude ? value : element)
                .longitude),
      );

      mapController.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } catch (e) {
      print("Error geocoding addresses or getting route: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        backgroundColor: const Color(0xFF2196F3),
        elevation: 2,
      ),
      body: Stack(
        children: [
          // Google Map widget
          GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _initialCameraPosition ?? const LatLng(0, 0),
              zoom: 11.0,
            ),
            polylines: polylines,
            markers: markers,
          ),

          // Search Bar
          Positioned(
            top: 16.0,
            left: 16.0,
            right: 16.0,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _startLocationController,
                      decoration: InputDecoration(
                        hintText: 'Your Location',
                        suffixIcon: IconButton(
                          onPressed: () {
                            _startLocationController.clear();
                          },
                          icon: const Icon(Icons.clear),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    TextField(
                      controller: _endLocationController,
                      decoration: InputDecoration(
                        hintText: 'Enter Destination',
                        suffixIcon: IconButton(
                          onPressed: () {
                            _endLocationController.clear();
                          },
                          icon: const Icon(Icons.clear),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: getRoute,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                      child: const Text('Get Route'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensure this is set to fixed
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CalendarScreen()),
            );
          } else if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const NotificationScreen()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WeatherApp()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            );
          }
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendars',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Weather',
          ),
          BottomNavigationBarItem( // Added Profile button
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
