import 'package:app/pages/profile_screen.dart';
import 'package:flutter/material.dart';
import 'notification_screen.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'weather_app.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calendar App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      home: const CalendarScreen(),
    );
  }
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<CalendarScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  DateTime? _selectedDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  bool _isAllDay = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  String _weatherInfo = 'Enter event location to display weather';
  bool _isLoadingWeather = false;

  final List<String> _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() {
        _selectedDate = pickedDate;
        _fetchWeatherData();
      });
    });
  }

  void _presentTimePicker(bool isStartTime) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((pickedTime) {
      if (pickedTime == null) return;
      setState(() {
        if (isStartTime) {
          _selectedStartTime = pickedTime;
        } else {
          _selectedEndTime = pickedTime;
        }
      });
    });
  }

  Future<void> _fetchWeatherData() async {
    if (_locationController.text.isEmpty || _selectedDate == null) {
      setState(() {
        _weatherInfo = 'Enter event location to display weather';
        _isLoadingWeather = false;
      });
      return;
    }

    setState(() {
      _isLoadingWeather = true;
    });

    final apiKey = '1e7999846c1f45699ac65336241509';
    final location = _locationController.text;
    final selectedDate = _selectedDate!;

    try {
      final url = Uri.parse(
          'http://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$location&days=20&aqi=yes');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final forecastDays = jsonData['forecast']['forecastday'];

        final forecastForSelectedDate = forecastDays.firstWhere(
          (forecast) => DateTime.parse(forecast['date']) == selectedDate,
          orElse: () => null,
        );

        if (forecastForSelectedDate != null) {
          final tempC =
              forecastForSelectedDate['day']['avgtemp_c']?.round() ?? 0;
          final condition =
              forecastForSelectedDate['day']['condition']['text'] ?? '';

          setState(() {
            _weatherInfo =
                'Expected weather on ${DateFormat('MMM dd').format(selectedDate)}: $tempC°C, $condition';
            _isLoadingWeather = false;
          });
        } else {
          setState(() {
            _weatherInfo = 'No forecast found for the selected date';
            _isLoadingWeather = false;
          });
        }
      } else {
        print('Error: ${response.statusCode}');
        setState(() {
          _weatherInfo = 'Failed to load weather data';
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      print('Error fetching weather: $e');
      setState(() {
        _weatherInfo = 'Failed to load weather data';
        _isLoadingWeather = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Calendar',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {
              _selectedDate = DateTime.now();
              _showEventDialog(context);
            },
          ),
        ],
      ),
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
        child: Column(
          children: <Widget>[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildYearDropdown(),
                _buildMonthDropdown(),
              ],
            ),
            Expanded(
              child: _buildCalendarGrid(),
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

  Widget _buildYearDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<int>(
        value: _selectedYear,
        items: _getYearOptions().map<DropdownMenuItem<int>>((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Text(value.toString()),
          );
        }).toList(),
        onChanged: (int? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedYear = newValue;
            });
          }
        },
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
        ),
        dropdownColor: Colors.white,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        underline: Container(
          height: 2,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildMonthDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<int>(
        value: _selectedMonth,
        items: List.generate(12, (index) => index + 1)
            .map<DropdownMenuItem<int>>((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Text(_months[value - 1]),
          );
        }).toList(),
        onChanged: (int? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedMonth = newValue;
            });
          }
        },
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
        ),
        dropdownColor: Colors.white,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
        underline: Container(
          height: 2,
          color: Colors.grey,
        ),
      ),
    );
  }

  List<int> _getYearOptions() {
    int currentYear = DateTime.now().year;
    List<int> years = [];
    for (int i = currentYear - 5; i <= currentYear + 5; i++) {
      years.add(i);
    }
    return years;
  }

  Widget _buildCalendarGrid() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMonthGrid(_selectedMonth, _selectedYear),
          _buildMonthGrid((_selectedMonth + 1) > 12 ? 1 : (_selectedMonth + 1),
              (_selectedMonth + 1) > 12 ? _selectedYear + 1 : _selectedYear),
        ],
      ),
    );
  }

Widget _buildMonthGrid(int month, int year) {
  DateTime firstDayOfMonth = DateTime(year, month, 1);
  DateTime lastDayOfMonth = DateTime(year, month + 1, 0);
  int firstWeekday = firstDayOfMonth.weekday; // Monday = 1, Sunday = 7
  int lastDay = lastDayOfMonth.day;

  // Convert weekday to fit the calendar grid (Sunday = 0, Monday = 1, ..., Saturday = 6)
  int startDayIndex = (firstWeekday % 7);

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _months[month - 1] + ' ' + year.toString(),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemCount: _weekdays.length + lastDay + startDayIndex,
          itemBuilder: (context, index) {
            if (index < _weekdays.length) {
              return Center(
                child: Text(
                  _weekdays[index],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }

            int dayNumber = index - _weekdays.length - startDayIndex + 1;

            if (dayNumber > 0 && dayNumber <= lastDay) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = DateTime(year, month, dayNumber);
                    _showEventDialog(context);
                  });
                },
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (_selectedDate != null &&
                              dayNumber == _selectedDate!.day &&
                              month == _selectedDate!.month &&
                              year == _selectedDate!.year)
                          ? Colors.blue
                          : Colors.transparent,
                    ),
                    child: Text(
                      dayNumber.toString(),
                      style: TextStyle(
                        color: (_selectedDate != null &&
                                dayNumber == _selectedDate!.day &&
                                month == _selectedDate!.month &&
                                year == _selectedDate!.year)
                            ? Colors.white
                            : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          },
        ),
      ],
    ),
  );
}



  Future<void> _addEventToFirestore() async {
    final _auth = FirebaseAuth.instance;
    final _firestore = FirebaseFirestore.instance;
    final user = _auth.currentUser;

    if (user != null) {
      try {
        final userDoc = _firestore.collection('Users').doc(user.uid);

        final currentEvents = (await userDoc.get()).data()?['events'] ?? [];

        final newEvent = {
          'title': _titleController.text,
          'location': _locationController.text,
          'details': _detailsController.text,
          'isAllDay': _isAllDay,
          'startDate': _selectedDate,
          'startTime': _selectedStartTime != null
              ? _selectedStartTime!.format(context)
              : null,
          'endDate': _selectedDate,
          'endTime': _selectedEndTime != null
              ? _selectedEndTime!.format(context)
              : null,
        };

        currentEvents.add(newEvent);

        await userDoc.update({'events': currentEvents});

        _titleController.clear();
        _locationController.clear();
        _detailsController.clear();
        _weatherInfo = 'Enter event location to display weather';
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Event added successfully!')),
        );
      } catch (e) {
        print('Error adding event: $e');
      }
    }
  }

  void _showEventDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          topRight: Radius.circular(16.0),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _weatherInfo =
                                'Enter event location to display weather';
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Text(
                          'New Event',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: _addEventToFirestore,
                          child: const Text(
                            'Add',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Title',
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        hintText: 'Location',
                        border: UnderlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _fetchWeatherData();
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _detailsController,
                      decoration: const InputDecoration(
                        hintText: 'Details',
                        border: UnderlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),
                    SwitchListTile(
                      title: const Text('All-day'),
                      value: _isAllDay,
                      onChanged: (newValue) {
                        setState(() {
                          _isAllDay = newValue;
                        });
                      },
                    ),
                    ListTile(
                      title: const Text('Starts'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: _presentDatePicker,
                            child: Text(DateFormat('MMM dd, yyyy')
                                .format(_selectedDate ?? DateTime.now())),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _presentTimePicker(true),
                            child: Text(
                              _selectedStartTime != null
                                  ? _selectedStartTime!.format(context)
                                  : '9:00 AM',
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: const Text('Ends'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: _presentDatePicker,
                            child: Text(DateFormat('MMM dd, yyyy')
                                .format(_selectedDate ?? DateTime.now())),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => _presentTimePicker(false),
                            child: Text(
                              _selectedEndTime != null
                                  ? _selectedEndTime!.format(context)
                                  : '10:00 AM',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: _isLoadingWeather
                          ? const CircularProgressIndicator()
                          : Text(
                              _weatherInfo,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}