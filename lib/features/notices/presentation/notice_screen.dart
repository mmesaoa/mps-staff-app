import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notice_controller.dart';

class NoticeScreen extends ConsumerWidget {
  const NoticeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticeState = ref.watch(noticeControllerProvider);

    return Scaffold(
      appBar: AppBar(
      ),
      body: SafeArea(
        child: noticeState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (notices) {
            if (notices.isEmpty) {
              return const Center(child: Text('No notices found.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16.0),
              itemCount: notices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notice = notices[index];
                return Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notice['title'],
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Published on: ${notice['published_at']}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Divider(height: 20),
                        Text(notice['content']),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}