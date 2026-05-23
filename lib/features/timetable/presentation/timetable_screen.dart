import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:school_erp_staff_app/features/timetable/presentation/timetable_providers.dart';
import 'package:school_erp_staff_app/shared/widgets/main_scaffold.dart';

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timetableAsync = ref.watch(timetableProvider);
    const dayOrder = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return MainScaffold(
      body: timetableAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (timetable) {
          if (timetable.isEmpty) {
            return const Center(child: Text('No timetable has been assigned to you.'));
          }

          // Filter and sort the days based on the order and available data
          final availableDays = dayOrder.where((day) => timetable.containsKey(day)).toList();

          return DefaultTabController(
            length: availableDays.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  tabs: availableDays.map((day) => Tab(text: day)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: availableDays.map((day) {
                      final periods = timetable[day]!;
                      return ListView.builder(
                        itemCount: periods.length,
                        itemBuilder: (context, index) {
                          final period = periods[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              leading: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(period.startTime, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const Text('to', style: TextStyle(fontSize: 10)),
                                  Text(period.endTime, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              title: Text(period.subject, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${period.className} - ${period.sectionName}'),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}