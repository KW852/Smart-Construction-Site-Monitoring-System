import 'package:flutter/material.dart';
import 'package:Monitoring_App/data.dart';
import 'package:Monitoring_App/location.dart';
import 'package:Monitoring_App/monitor.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<Widget> pages = [
    DataPage(),
    const LocationPage(),
    MonitorPage(),
  ];

  int currentPage = 0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentPage],

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        selectedItemColor: Color.fromARGB(255, 255, 175, 0),
        unselectedItemColor: Color.fromARGB(255, 80, 80, 80),
        currentIndex: currentPage,
        onTap: (value) {
          setState(() {
            currentPage = value;
          });
        },
        items: const [

          BottomNavigationBarItem(
            icon: Icon(
              Icons.analytics,
            ),
            label: "Data",
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.location_on,
            ),
            label: "Location",
          ),

          BottomNavigationBarItem(
            icon: Icon(
              Icons.monitor,
            ),
            label: "Monitor",
          ),

        ],
      ),
    );
  }
}