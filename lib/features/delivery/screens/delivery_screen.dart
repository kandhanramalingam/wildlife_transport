import 'package:flutter/material.dart';
import '../tabs/completed_tab.dart';
import '../tabs/today_tab.dart';
import '../tabs/upcoming_tab.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<CompletedTabState> _completedTabKey = GlobalKey();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index != 2 || _tabController.indexIsChanging) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _completedTabKey.currentState?.refresh();
    });
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deliveries'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const TodayTab(),
          const UpcomingTab(),
          CompletedTab(key: _completedTabKey),
        ],
      ),
    );
  }
}
