import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'calendar_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Weather App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      home: const WeatherPage(),
    );
  }
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({Key? key}) : super(key: key);

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final String apiKey = 'fa3242d6725f427095b144358240908';
  String location = 'Colombo';
  late TextEditingController _locationController;
  int temperature = 0;
  String description = '';
  int aqi = 0;
  List<Forecast> forecastData = [];
  int humidity = 0;
  double windSpeed = 0.0;
  double pressure = 0.0;
  int uvIndex = 0;
  double precipitationProbability = 0.0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: location);
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
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

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        setState(() {
          location = placemark.locality ?? 'Colombo';
          _locationController.text = location;
          _fetchWeatherData();
        });
      }
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> _fetchWeatherData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final url = Uri.parse(
          'http://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$location&days=3&aqi=yes');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        setState(() {
          temperature = jsonData['current']['temp_c'] != null
              ? jsonData['current']['temp_c'].round()
              : 0;
          description = jsonData['current']['condition']['text'] ?? '';
          aqi = jsonData['current']['air_quality']['us-epa-index'] != null
              ? jsonData['current']['air_quality']['us-epa-index'].round()
              : 0;
          forecastData = (jsonData['forecast']['forecastday'] as List)
              .map((forecast) => Forecast.fromJson(forecast))
              .toList();
          humidity = jsonData['current']['humidity'] ?? 0;
          windSpeed = jsonData['current']['wind_kph'] ?? 0.0;
          pressure = jsonData['current']['pressure_mb'] ?? 0.0;
          uvIndex = jsonData['current']['uv'] != null
              ? jsonData['current']['uv'].round()
              : 0;
          precipitationProbability = jsonData['forecast']['forecastday'][0]
                      ['day']['daily_chance_of_rain'] !=
                  null
              ? jsonData['forecast']['forecastday'][0]['day']
                      ['daily_chance_of_rain']
                  .toDouble()
              : 0.0;
          isLoading = false;
        });
      } else {
        print('Error: ${response.statusCode}');
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE1F6F9),
              Colors.white,
            ],
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  AppBar(
                    title: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: TextField(
                          controller: _locationController,
                          decoration: InputDecoration(
                            hintText: 'Enter Location',
                            border: InputBorder.none,
                            suffixIcon: IconButton(
                              onPressed: () {
                                _locationController.clear();
                              },
                              icon: const Icon(Icons.clear),
                            ),
                          ),
                          onSubmitted: (value) {
                            setState(() {
                              location = value;
                              _fetchWeatherData();
                            });
                          },
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontSize: 24,
                          ),
                        ),
                      ),
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    centerTitle: true,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Center(
                            child: Text(
                              '$temperature°C',
                              style: const TextStyle(
                                  fontSize: 80.0, fontWeight: FontWeight.w300),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Center(
                            child: Text(
                              description,
                              style: const TextStyle(fontSize: 24.0),
                            ),
                          ),
                          const SizedBox(height: 20.0),
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: aqi <= 50
                                  ? Colors.green
                                  : aqi <= 100
                                      ? Colors.yellow
                                      : Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'AQI',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 225, 241, 248),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                const Center(
                                  child: Text(
                                    '3-Day Forecast',
                                    style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: forecastData.length,
                                  itemBuilder: (context, index) {
                                    return ListTile(
                                      leading: Image.asset(
                                          'assets/images/${forecastData[index].icon}.png'),
                                      title: Text(
                                        forecastData[index].day,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                      trailing: Text(
                                        '${forecastData[index].high.round()}/${forecastData[index].low.round()}°C',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 225, 241, 248),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              children: [
                                WeatherParameterRow(
                                    parameter: 'Humidity', value: '$humidity%'),
                                WeatherParameterRow(
                                    parameter: 'Wind Speed',
                                    value:
                                        '${windSpeed.toStringAsFixed(1)} kph'),
                                WeatherParameterRow(
                                    parameter: 'UV', value: '$uvIndex'),
                                WeatherParameterRow(
                                    parameter: 'Pressure',
                                    value:
                                        '${pressure.toStringAsFixed(1)} mbar'),
                                WeatherParameterRow(
                                    parameter: 'Feels Like',
                                    value: '$temperature°C'),
                                WeatherParameterRow(
                                    parameter: 'Chance of Rain',
                                    value:
                                        '${precipitationProbability.toStringAsFixed(1)}%'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class WeatherParameterRow extends StatelessWidget {
  final String parameter;
  final String value;
  const WeatherParameterRow(
      {Key? key, required this.parameter, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            parameter,
            style: const TextStyle(fontSize: 18),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class Forecast {
  final String day;
  final double high;
  final double low;
  final String icon;

  Forecast({
    required this.day,
    required this.high,
    required this.low,
    required this.icon,
  });

  factory Forecast.fromJson(Map<String, dynamic> json) {
    return Forecast(
      day: json['date'],
      high: json['day']['maxtemp_c'],
      low: json['day']['mintemp_c'],
      icon: json['day']['condition']['icon']
          .toString()
          .split('/')
          .last
          .replaceAll('.png', ''),
    );
  }
}