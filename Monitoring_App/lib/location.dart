import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  _LocationPageState createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  double latitude = 0.0;
  double longitude = 0.0;

  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();

  CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(0.0, 0.0),
    zoom: 18.4746,
  );

  final Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    initializeLocation();
  }

  void initializeLocation() {
    DatabaseReference latitudeRef = FirebaseDatabase.instance.ref().child('Site_1/Latitude');
    latitudeRef.onValue.listen((event) {
      setState(() {
        latitude = double.tryParse(event.snapshot.value.toString()) ?? 0.0;
        updateMap();
      });
    });

    DatabaseReference longitudeRef = FirebaseDatabase.instance.ref().child('Site_1/Longitude');
    longitudeRef.onValue.listen((event) {
      setState(() {
        longitude = double.tryParse(event.snapshot.value.toString()) ?? 0.0;
        updateMap();
      });
    });
  }

  void updateMap() {
    final LatLng position = LatLng(latitude, longitude);
    _kGooglePlex = CameraPosition(
      target: position,
      zoom: 18.4746,
    );

    markers.clear();
    markers.add(
      Marker(
        markerId: MarkerId('Marker'),
        position: position,
        icon: BitmapDescriptor.defaultMarker,
      )
    );

    _controller.future.then((controller) {
      controller.animateCamera(CameraUpdate.newCameraPosition(_kGooglePlex));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _goToMyLocation,
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              child: const Icon(Icons.my_location),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    final GoogleMapController controller = await _controller.future;
    LatLng myLocation = await getMyLocation();
    controller.animateCamera(CameraUpdate.newLatLng(myLocation));
  }

  Future<LatLng> getMyLocation() async {
    return LatLng(latitude, longitude);
  }
}
