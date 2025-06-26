import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:Monitoring_App/main.dart';

class DataPage extends StatefulWidget {
  const DataPage({super.key});

  @override
  _DataPageState createState() => _DataPageState();
}

class _DataPageState extends State<DataPage> {
  String humidity = "0";
  String temperature = "0";
  String pitch = "0";
  String roll = "0";
  String decibel = "0";
  String PM1 = "0";
  String PM2_5 = "0";
  String PM10 = "0";
  String no_helmet = "0";

  // final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();

    // initializeNotifications();

    setupFirebaseListeners();
  }

  Future<void> showNotification(String title, String body, {int id = 0}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.high,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iOSDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: body,
    );
  }

  void setupFirebaseListeners() {
    DatabaseReference humidityRef = FirebaseDatabase.instance.ref().child('Site_1/Humidity');
    DatabaseReference temperatureRef = FirebaseDatabase.instance.ref().child('Site_1/Temperature');
    DatabaseReference pitchRef = FirebaseDatabase.instance.ref().child('Site_1/Pitch');
    DatabaseReference rollRef = FirebaseDatabase.instance.ref().child('Site_1/Roll');
    DatabaseReference decibelRef = FirebaseDatabase.instance.ref().child('Site_1/Decibel');
    DatabaseReference PM1Ref = FirebaseDatabase.instance.ref().child('Site_1/PM1');
    DatabaseReference PM2_5Ref = FirebaseDatabase.instance.ref().child('Site_1/PM2_5');
    DatabaseReference PM10Ref = FirebaseDatabase.instance.ref().child('Site_1/PM10');
    DatabaseReference no_helmetRef = FirebaseDatabase.instance.ref().child('Site_1/no_helmet');

    humidityRef.onValue.listen((event) {
      setState(() {
        humidity = event.snapshot.value.toString() + "%";
      });
      checkAndTriggerWarnings();
    });

    temperatureRef.onValue.listen((event) {
      setState(() {
        temperature = event.snapshot.value.toString() + "°C";
      });
      checkAndTriggerWarnings();
    });

    pitchRef.onValue.listen((event) {
      setState(() {
        pitch = event.snapshot.value.toString() + "°";
      });
      checkAndTriggerWarnings();
    });

    rollRef.onValue.listen((event) {
      setState(() {
        roll = event.snapshot.value.toString() + "°";
      });
      checkAndTriggerWarnings();
    });

    decibelRef.onValue.listen((event) {
      setState(() {
        decibel = event.snapshot.value.toString() + " dB";
      });
      checkAndTriggerWarnings();
    });

    PM1Ref.onValue.listen((event) {
      setState(() {
        PM1 = event.snapshot.value.toString() + " μg/m3";
      });
      checkAndTriggerWarnings();
    });

    PM2_5Ref.onValue.listen((event) {
      setState(() {
        PM2_5 = event.snapshot.value.toString() + " μg/m3";
      });
      checkAndTriggerWarnings();
    });

    PM10Ref.onValue.listen((event) {
      setState(() {
        PM10 = event.snapshot.value.toString() + " μg/m3";
      });
      checkAndTriggerWarnings();
    });

    no_helmetRef.onValue.listen((event) {
      setState(() {
        no_helmet = event.snapshot.value.toString() + " people";
      });
      checkAndTriggerWarnings();
    });

  }

  Future<String> getAdviceFor(String parameter, {int retries = 5}) async {
    final ref = FirebaseDatabase.instance.ref("Site_1/Recommendation/$parameter");

    for (int i = 0; i < retries; i++) {
      final snapshot = await ref.get();
      final value = snapshot.value?.toString();

      if (value != null && value.trim() != "" && value != "0") {
        return value;
      }

      await Future.delayed(const Duration(milliseconds: 300));
    }

    return "No advice available.";
  }

  Future<void> checkAndTriggerWarnings() async {
    double humidityValue = double.tryParse(humidity.replaceAll("%", "")) ?? 0;
    double temperatureValue = double.tryParse(temperature.replaceAll("°C", "")) ?? 0;
    double pitchValue = double.tryParse(pitch.replaceAll("°", "")) ?? 0;
    double rollValue = double.tryParse(roll.replaceAll("°", "")) ?? 0;
    double decibelValue = double.tryParse(decibel.replaceAll("dB", "")) ?? 0;
    double PM1Value = double.tryParse(PM1.replaceAll("μg/m3", "")) ?? 0;
    double PM2_5Value = double.tryParse(PM2_5.replaceAll("μg/m3", "")) ?? 0;
    double PM10Value = double.tryParse(PM10.replaceAll("μg/m3", "")) ?? 0;
    int no_helmetValue = int.tryParse(no_helmet.replaceAll(" people", "")) ?? 0;

    int notificationId = 0;

    if (humidityValue > 85) {
      final advice = await getAdviceFor("Humidity");
      await showNotification(
        "Warning!",
        "Humidity: $humidityValue%\nAdvice:\n$advice",
        id: notificationId++,
      );
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (temperatureValue > 33) {
      final advice = await getAdviceFor("Temperature");
      await showNotification(
        "Warning!",
        "Temperature: $temperatureValue°C\nAdvice:\n$advice",
        id: notificationId++,
      );
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (pitchValue > 5) {
      final advice = await getAdviceFor("Pitch");
      await showNotification(
        "Warning!",
        "Pitch: $pitchValue°\nAdvice:\n$advice",
        id: notificationId++,
      );
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (rollValue > 5) {
      final advice = await getAdviceFor("Roll");
      await showNotification(
        "Warning!",
        "Roll: $rollValue°\nAdvice:\n$advice",
        id: notificationId++,
      );
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (decibelValue > 85) {
      final advice = await getAdviceFor("Decibel");
      await showNotification(
        "Warning!",
        "Decibel: $decibelValue dB\nAdvice:\n$advice",
        id: notificationId++,
      );
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (PM1Value > 35) {
      final advice = await getAdviceFor("PM1");
      await showNotification(
        "Warning!",
        "PM1.0: $PM1Value μg/m3\nAdvice:\n$advice",
        id: notificationId++,
      );
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (PM2_5Value > 50) {
      final advice = await getAdviceFor("PM2_5");
      await showNotification(
        "Warning!",
        "PM2.5: $PM2_5Value μg/m3\nAdvice:\n$advice",
        id: notificationId++,
      );
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (PM10Value > 100) {
      final advice = await getAdviceFor("PM10");
      await showNotification(
        "Warning!",
        "PM10: $PM10Value μg/m3\nAdvice:\n$advice",
        id: notificationId++,
      );
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (no_helmetValue > 0) {
      final advice = await getAdviceFor("no_helmet");
      await showNotification(
        "Warning!",
        "There are $no_helmetValue people without helmets.\nAdvice:\n$advice",
        id: notificationId++,
      );
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Widget buildCard(String title, String itemCount, IconData icon, Color iconColor) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Card(
        color: const Color.fromARGB(255, 255, 255, 255),
        elevation: 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: iconColor, size: 54.0),
                const SizedBox(height: 10.0),
                Text(
                  title,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 0, 0, 0),
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                ),
                const SizedBox(height: 5.0),
                Text(
                  itemCount,
                  style: const TextStyle(
                    color: Color.fromARGB(255, 255, 160, 0),
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('EEEE, MMMM d').format(now);
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 240, 240, 240),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dashboard",
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 150, 0),
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Colors.black),
                      const SizedBox(width: 10.0),
                      Text(
                        formattedDate,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Center(
                    child: Wrap(
                      spacing: 20.0,
                      runSpacing: 20.0,
                      children: [
                        buildCard("Temperature", temperature, Icons.thermostat, Colors.red),
                        buildCard("Humidity", humidity, Icons.opacity, Colors.blue),
                        buildCard("Pitch", pitch, Icons.swap_vert_circle, Colors.green),
                        buildCard("Roll", roll, Icons.swap_horizontal_circle, Colors.indigo),
                        buildCard("Decibel", decibel, Icons.volume_up, Colors.cyan),
                        buildCard("PM1.0", PM1, Icons.bubble_chart_rounded, Colors.grey.shade900),
                        buildCard("PM2.5", PM2_5, Icons.bubble_chart_rounded, Colors.grey.shade900),
                        buildCard("PM10", PM10, Icons.bubble_chart_rounded, Colors.grey.shade900),
                        buildCard("Non-Helmet", no_helmet, Icons.person_3, Colors.yellowAccent.shade700),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}