import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hms_app/models/dtos/booking_schedule_item.dart';
import 'package:hms_app/models/dtos/reception_task_data.dart';
import 'package:hms_app/models/enums/reception_task_type.dart';
import 'package:hms_app/providers/booking_provider.dart';
import 'package:hms_app/views/receptionist/reception_task_list_view.dart';
import 'package:hms_app/views/receptionist/widgets/reception_task_widgets.dart';
import 'package:hms_app/widgets/app_drawer.dart';

class ReceptionTasksView extends StatefulWidget {
  const ReceptionTasksView({super.key});

  @override
  State<ReceptionTasksView> createState() => _ReceptionTasksViewState();
}

class _TaskGroup {
  final ReceptionTaskType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<BookingScheduleItem> bookings;
  final bool urgent;

  const _TaskGroup({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.bookings,
    this.urgent = false,
  });
}

class _ReceptionTasksViewState extends State<ReceptionTasksView> {
  static const _soonThreshold = Duration(minutes: 30);

  BookingProvider get _bookingProvider => context.read<BookingProvider>();
  late Future<ReceptionTaskData> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _fetchTasks();
  }

  Future<ReceptionTaskData> _fetchTasks() async {
    final results = await Future.wait([
      _bookingProvider.getTodayCheckins(),
      _bookingProvider.getUpcomingCheckouts(threshold: _soonThreshold),
    ]);

    return ReceptionTaskData(checkins: results[0], checkouts: results[1]);
  }

  void _loadTasks() {
    if (!mounted) return;
    setState(() {
      _tasksFuture = _fetchTasks();
    });
  }

  Future<void> _refreshTasks() async {
    setState(() {
      _tasksFuture = _fetchTasks();
    });
    await _tasksFuture;
  }

  List<_TaskGroup> _buildTaskGroups(ReceptionTaskData data) {
    final upcomingCheckins = _upcomingCheckins(data.checkins);
    final overdueCheckins = _overdueCheckins(data.checkins);
    final noShows = _noShows(data.checkins);
    final upcomingCheckouts = _upcomingCheckouts(data.checkouts);
    final overdueCheckouts = _overdueCheckouts(data.checkouts);

    return [
      _TaskGroup(
        type: ReceptionTaskType.upcomingCheckin,
        title: 'Sắp check-in',
        subtitle: 'Khách có lịch nhận phòng trong 30 phút tới',
        icon: Icons.login_outlined,
        bookings: upcomingCheckins,
      ),
      _TaskGroup(
        type: ReceptionTaskType.overdueCheckin,
        title: 'Quá giờ check-in',
        subtitle: 'Khách quá giờ check-in nhưng chưa đến mốc no-show',
        icon: Icons.phone_missed_outlined,
        bookings: overdueCheckins,
        urgent: overdueCheckins.isNotEmpty,
      ),
      _TaskGroup(
        type: ReceptionTaskType.noShow,
        title: 'No-show',
        subtitle: 'Khách chưa check-in sau 18:00 ngày nhận phòng',
        icon: Icons.event_busy_outlined,
        bookings: noShows,
        urgent: noShows.isNotEmpty,
      ),
      _TaskGroup(
        type: ReceptionTaskType.upcomingCheckout,
        title: 'Sắp checkout',
        subtitle: 'Khách cần chuẩn bị trả phòng trong 30 phút tới',
        icon: Icons.logout_outlined,
        bookings: upcomingCheckouts,
      ),
      _TaskGroup(
        type: ReceptionTaskType.overdueCheckout,
        title: 'Quá giờ checkout',
        subtitle: 'Có thể phát sinh phụ thu trả phòng muộn',
        icon: Icons.warning_amber_outlined,
        bookings: overdueCheckouts,
        urgent: overdueCheckouts.isNotEmpty,
      ),
    ];
  }

  List<BookingScheduleItem> _overdueCheckins(List<BookingScheduleItem> items) {
    final now = DateTime.now();
    return items.where((item) {
      final checkin = item.checkInDateTime.toLocal();
      return checkin.isBefore(now) && !_isNoShow(item, now);
    }).toList();
  }

  List<BookingScheduleItem> _upcomingCheckins(List<BookingScheduleItem> items) {
    final now = DateTime.now();
    final limit = now.add(_soonThreshold);
    return items.where((item) {
      final checkin = item.checkInDateTime.toLocal();
      return !checkin.isBefore(now) && !checkin.isAfter(limit);
    }).toList();
  }

  List<BookingScheduleItem> _noShows(List<BookingScheduleItem> items) {
    final now = DateTime.now();
    return items.where((item) => _isNoShow(item, now)).toList();
  }

  bool _isNoShow(BookingScheduleItem item, DateTime now) {
    final checkin = item.checkInDateTime.toLocal();
    final noShowCutoff = DateTime(checkin.year, checkin.month, checkin.day, 18);

    return now.isAfter(noShowCutoff) || now.isAtSameMomentAs(noShowCutoff);
  }

  List<BookingScheduleItem> _overdueCheckouts(List<BookingScheduleItem> items) {
    final now = DateTime.now();
    return items
        .where((item) => item.checkoutDateTime.toLocal().isBefore(now))
        .toList();
  }

  List<BookingScheduleItem> _upcomingCheckouts(
    List<BookingScheduleItem> items,
  ) {
    final now = DateTime.now();
    return items.where((item) {
      final checkout = item.checkoutDateTime.toLocal();
      return !checkout.isBefore(now);
    }).toList();
  }

  Future<void> _openTaskGroup(_TaskGroup group) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReceptionTaskListView(
          title: group.title,
          subtitle: group.subtitle,
          type: group.type,
          bookings: group.bookings,
        ),
      ),
    );
    if (mounted) _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Việc cần xử lý', style: TextStyle(color: color.onSurface)),
        centerTitle: true,
        backgroundColor: color.surface,
        iconTheme: IconThemeData(color: color.onSurface),
        elevation: 0,
        actions: [
          IconButton(onPressed: _loadTasks, icon: const Icon(Icons.refresh)),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: _refreshTasks,
        child: FutureBuilder<ReceptionTaskData>(
          future: _tasksFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 80),
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Lỗi tải việc cần xử lý: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }

            final groups = _buildTaskGroups(snapshot.data!);
            final total = groups.fold<int>(
              0,
              (sum, group) => sum + group.bookings.length,
            );

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                TaskOverview(count: total),
                const SizedBox(height: 16),
                ...groups.map(
                  (group) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TaskGroupCard(
                      title: group.title,
                      subtitle: group.subtitle,
                      icon: group.icon,
                      count: group.bookings.length,
                      urgent: group.urgent,
                      onTap: () => _openTaskGroup(group),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
