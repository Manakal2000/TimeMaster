import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'google_map_page.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final String apiKey = '855bdde4dd9c4ce187b50045243007';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore
            .collection('Users')
            .doc(_auth.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final userEvents = snapshot.data!['events'] as List?;
          if (userEvents == null || userEvents.isEmpty) {
            return const Center(
              child: Text('No events yet.'),
            );
          }

          return ListView.builder(
            itemCount: userEvents.length,
            itemBuilder: (context, index) {
              final event = userEvents[index] as Map<String, dynamic>;
              final startDate = (event['startDate'] as Timestamp).toDate();
              if (_isTodayOrNextTwoDays(startDate)) {
                return FutureBuilder<String>(
                  future: _fetchWeatherForDate(startDate, event['location']),
                  builder: (context, weatherSnapshot) {
                    if (weatherSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text('Loading...'),
                      );
                    } else if (weatherSnapshot.hasError) {
                      print("Weather API Error: ${weatherSnapshot.error}");
                      return const ListTile(
                        title: Text('Error: Failed to fetch weather.'),
                      );
                    } else {
                      return _buildNotificationItem(
                          event, weatherSnapshot.data);
                    }
                  },
                );
              } else {
                return const SizedBox.shrink();
              }
            },
          );
        },
      ),
    );
  }

  Future<String> _fetchWeatherForDate(DateTime date, String? location) async {
    if (location == null) {
      return "Location not available";
    }

    // Normalize dates to ignore time differences and only focus on the day count
    final today = DateTime.now();
    final targetDate = DateTime(date.year, date.month, date.day); // Only date, ignore time
    final normalizedToday = DateTime(today.year, today.month, today.day); // Only date, ignore time

    // Get the number of days from today
    final daysFromToday = targetDate.difference(normalizedToday).inDays;

    // Ensure the date is within the range of forecast data (usually up to 10 days)
    if (daysFromToday < 0 || daysFromToday > 10) {
      return "Weather data unavailable";
    }

    final url = Uri.parse(
        'http://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$location&days=${daysFromToday + 1}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        // Use the correct index for the forecast day
        final forecastDay = jsonData['forecast']['forecastday'][daysFromToday];
        final condition = forecastDay['day']['condition']['text'];
        return condition;
      } else {
        throw Exception('Failed to load weather data: ${response.statusCode}');
      }
    } catch (e) {
      return 'Weather data unavailable';
    }
  }

  bool _isTodayOrNextTwoDays(DateTime eventDate) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final dayAfterTomorrow = today.add(const Duration(days: 2));

    return eventDate.year == today.year &&
            eventDate.month == today.month &&
            eventDate.day == today.day ||
        eventDate.year == tomorrow.year &&
            eventDate.month == tomorrow.month &&
            eventDate.day == tomorrow.day ||
        eventDate.year == dayAfterTomorrow.year &&
            eventDate.month == dayAfterTomorrow.month &&
            eventDate.day == dayAfterTomorrow.day;
  }

  Widget _buildNotificationItem(
      Map<String, dynamic> event, String? weatherDescription) {
    final title = event['title'] as String;
    final location = event['location'] as String?;
    final startDate = (event['startDate'] as Timestamp).toDate();
    final startTime = event['startTime'] as String?;
    final isAllDay = event['isAllDay'] as bool;

    String startDateTimeString = DateFormat('MMM dd, yyyy').format(startDate);
    if (!isAllDay && startTime != null) {
      startDateTimeString += ' at $startTime';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        leading: const Icon(Icons.calendar_today, size: 32),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (location != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  location,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Starts: $startDateTimeString',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            if (weatherDescription != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Weather: $weatherDescription',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
          ],
        ),
        trailing: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GoogleMapPage(
                  eventLocation: location,
                ),
              ),
            );
          },
          icon: const Icon(
            Icons.location_on,
            color: Colors.blue,
          ),
        ),
      ),
    );
  }
}
