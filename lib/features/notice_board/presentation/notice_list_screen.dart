import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:school_erp_staff_app/shared/widgets/main_scaffold.dart';
import 'package:school_erp_staff_app/features/auth/presentation/auth_controller.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'notice_providers.dart';

class NoticeListScreen extends ConsumerWidget {
  const NoticeListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noticeListState = ref.watch(noticeListProvider);
    
    // ✅ 1. Get the AsyncValue object which wraps the user's state.
    final asyncUser = ref.watch(authControllerProvider);
    // ✅ 2. Safely get the actual User object from the '.value' property.
    final user = asyncUser.value;

    // ✅ 3. This check will now work correctly on the actual user data.
    final canCreateNotices = user?.role == 'school_admin';

    return MainScaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(noticeListProvider.future),
        child: noticeListState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            String errorMessage = '$err';
            if (errorMessage.contains('403')) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_person, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Access Restricted',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'The notice board is currently restricted for your role. Please contact your administrator for access.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Center(child: Text('Error: $err'));
          },
          data: (notices) {
            if (notices.isEmpty) {
              return const Center(child: Text('No notices have been published yet.'));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 80), // Padding for FAB
              itemCount: notices.length,
              itemBuilder: (context, index) {
                final notice = notices[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: 2,
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      context.go('/notices/detail', extra: notice);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notice['title'] ?? 'No Title',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Published on: ${DateFormat('dd MMM, yyyy').format(DateTime.parse(notice['published_at']))}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Divider(height: 20),
                          
                          // Show a clipped, summary version of the content
                          HtmlWidget(
                            notice['content'] ?? '',
                            textStyle: Theme.of(context).textTheme.bodyMedium,
                            // This will limit the content to a maximum of 3 lines.
                            customStylesBuilder: (element) {
                              if (element.localName == 'body') {
                                return {
                                  'max-lines': '3',
                                  'text-overflow': 'ellipsis',
                                };
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: canCreateNotices ? FloatingActionButton(
        onPressed: () async {
          // Use push to open the create screen, then invalidate the list when it returns
          final result = await context.push('/notices/create');
          if (result == true) { // check if a notice was successfully created
            ref.invalidate(noticeListProvider);
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Notice',
      ) : null,
    );
  }
}