import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weatherapp/bloc/weather_bloc_bloc.dart';
import 'package:weatherapp/screens/home_screen.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LocationWrapper(),
    );
  }
}

class LocationWrapper extends StatefulWidget {
  const LocationWrapper({super.key});

  @override
  _LocationWrapperState createState() => _LocationWrapperState();
}

class _LocationWrapperState extends State<LocationWrapper> {
  Future<Position>? _positionFuture;

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    try {
      Position position = await _determinePosition();
      setState(() {
        _positionFuture = Future.value(position);
      });
    } catch (e) {
      _showLocationDialog(context, e.toString());
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      await Future.delayed(const Duration(seconds: 5));
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable them.';
      }
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw 'Location permissions are denied. Please enable them.';
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw 'Location permissions are permanently denied. We cannot request permissions.';
    }

    return await Geolocator.getCurrentPosition();
  }

  void _showLocationDialog(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Location Required'),
            content: Text(message),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _checkLocation();
                },
              ),
            ],
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Position>(
      future: _positionFuture,
      builder: (context, snap) {
        if (snap.hasData) {
          return BlocProvider<WeatherBlocBloc>(
            create: (context) => WeatherBlocBloc()..add(FetchWeather(snap.data as Position)),
            child: const HomeScreen(),
          );
        } else if (snap.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                snap.error.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            backgroundColor: Colors.black,
          );
        } else {
          return  Scaffold(
            body: Center(
              child: Container(),
            ),
            backgroundColor: Colors.black,
          );
        }
      },
    );
  }
}
