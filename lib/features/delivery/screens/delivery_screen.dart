import 'package:flutter/material.dart';
import '../tabs/today_tab.dart';
import '../tabs/upcoming_tab.dart';

class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Deliveries'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Today'),
              Tab(text: 'Upcoming'),
            ],
          ),
        ),
        body: const TabBarView(children: [TodayTab(), UpcomingTab()]),
      ),
    );
  }
}
