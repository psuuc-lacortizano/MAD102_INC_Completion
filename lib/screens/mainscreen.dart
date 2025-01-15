import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/friendlist.dart';
import 'package:flutter_application_1/screens/logout.dart';
import 'package:flutter_application_1/services/auth_services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final auth = AuthServices();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Position? _currentPosition;
  bool _isLocationSharing = false;
  BitmapDescriptor? _userIcon;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _friendsLocationStream;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadLocationSharingStatus();
    _loadIcons();
    _startListeningToFriendsLocations();
  }

  Future<void> _loadIcons() async {
    _userIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    setState(() {});
  }

  Future<void> _loadLocationSharingStatus() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User is not authenticated');
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      bool locationSharing = userDoc['locationSharing'] ?? false;

      setState(() {
        _isLocationSharing = locationSharing;
      });

      if (_isLocationSharing && _currentPosition != null) {
        _addMarker(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          'My Location',
          'This is your current location.',
          _userIcon!,
        );
      }
    } catch (e) {
      print('Error loading location sharing status: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied.');
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
    });

    if (_mapController != null && _currentPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }

    if (_isLocationSharing) {
      _addMarker(
        LatLng(position.latitude, position.longitude),
        'My Location',
        'This is your current location.',
        _userIcon!,
      );
      _updateLocationInFirestore(position.latitude, position.longitude);
    }

    _startListeningToUserLocation();
  }

  void _startListeningToUserLocation() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((Position position) {
      if (_isLocationSharing) {
        setState(() {
          _currentPosition = position;
        });

        _updateMarker('My Location',
            LatLng(position.latitude, position.longitude), _userIcon!);
        _updateLocationInFirestore(position.latitude, position.longitude);
      }
    });
  }

  void _addMarker(
      LatLng position, String markerId, String snippet, BitmapDescriptor icon) {
    final newMarker = Marker(
      markerId: MarkerId(markerId),
      position: position,
      infoWindow: InfoWindow(title: markerId, snippet: snippet),
      icon: icon,
    );

    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == markerId);
      _markers.add(newMarker);
    });
  }

  void _updateMarker(String markerId, LatLng position, BitmapDescriptor icon) {
    _addMarker(position, markerId, 'Updated Location', icon);
  }

  void _startListeningToFriendsLocations() {
    _friendsLocationStream = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      Set<Marker> updatedMarkers = {};

      for (var doc in snapshot.docs) {
        if (doc.id == FirebaseAuth.instance.currentUser?.uid) continue;

        if (doc['locationSharing'] == true && doc['location'] != null) {
          GeoPoint location = doc['location'];
          String friendName = doc['name'] ?? 'Friend';

          int hash = friendName.hashCode;
          double hue = (hash % 360).toDouble();

          BitmapDescriptor friendIcon =
              BitmapDescriptor.defaultMarkerWithHue(hue);

          LatLng friendLocation = LatLng(location.latitude, location.longitude);

          updatedMarkers.add(
            Marker(
              markerId: MarkerId(friendName),
              position: friendLocation,
              infoWindow: InfoWindow(
                title: friendName,
                snippet: '$friendName\'s location',
              ),
              icon: friendIcon,
            ),
          );
        }
      }

      if (_isLocationSharing && _currentPosition != null) {
        updatedMarkers.add(
          Marker(
            markerId: const MarkerId('My Location'),
            position: LatLng(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            ),
            infoWindow: const InfoWindow(
              title: 'My Location',
              snippet: 'This is your current location.',
            ),
            icon: _userIcon!,
          ),
        );
      }

      setState(() {
        _markers = updatedMarkers;
      });
    });
  }

  void _toggleLocationSharing() {
    setState(() {
      _isLocationSharing = !_isLocationSharing;

      if (_isLocationSharing && _currentPosition != null) {
        _addMarker(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          'My Location',
          'This is your current location.',
          _userIcon!,
        );

        _startListeningToUserLocation();
        _updateLocationInFirestore(
          _currentPosition!.latitude,
          _currentPosition!.longitude,
        );
      } else {
        _positionStream?.cancel();
        _markers
            .removeWhere((marker) => marker.markerId.value == 'My Location');
        _removeLocationFromFirestore();
      }
    });
  }

  Future<void> _updateLocationInFirestore(
      double latitude, double longitude) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User is not authenticated');
        return;
      }

      String userId = user.uid;
      GeoPoint geoPoint = GeoPoint(latitude, longitude);

      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'location': geoPoint,
        'locationSharing': _isLocationSharing,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating location in Firestore: $e');
    }
  }

  Future<void> _removeLocationFromFirestore() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User is not authenticated');
        return;
      }
      String userId = user.uid;

      DocumentReference userDocRef =
          FirebaseFirestore.instance.collection('users').doc(userId);

      await userDocRef.update({
        'location': FieldValue.delete(),
        'locationSharing': false,
      });
    } catch (e) {
      print('Error removing location from Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LocaLink'),
        backgroundColor: const Color.fromARGB(255, 42, 152, 255),
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const FriendList(),
              ),
            );
          },
          icon: const Icon(Icons.people_alt_outlined),
        ),
        actions: [
          Switch(
            value: _isLocationSharing,
            onChanged: (value) {
              _toggleLocationSharing();
            },
            activeColor: const Color.fromARGB(255, 11, 17, 29),
            inactiveThumbColor: const Color.fromARGB(255, 133, 36, 31),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const logout(),
                ),
              );
            },
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude, _currentPosition!.longitude)
                  : LatLng(0.0, 0.0),
              zoom: 14.0,
            ),
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
          ),
        ],
      ),
    );
  }
}
