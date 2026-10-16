import 'package:flutter/material.dart';
import '../delivery/screens/delivery_screen.dart';
import '../profile/screens/profile_screen.dart';
import '../../core/location/tracking_status_banner.dart';
import '../delivery/widgets/offloading_sync_banner.dart';

class HomeScreen extends StatefulWidget {
  final bool isSelfLoad;

  const HomeScreen({super.key, this.isSelfLoad = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  List<Widget> get _screens => [
    DeliveryScreen(
      key: ValueKey(widget.isSelfLoad),
      isSelfLoad: widget.isSelfLoad,
    ),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TrackingStatusBanner(),
          const OffloadingSyncBanner(),
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Delivery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
