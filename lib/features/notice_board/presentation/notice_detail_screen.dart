import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:intl/intl.dart';

class NoticeDetailScreen extends StatelessWidget {
  final Map<String, dynamic> notice;

  const NoticeDetailScreen({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    final title = notice['title'] ?? 'Notice Details';
    final content = notice['content'] ?? 'No content available.';
    final publishedDate = notice['published_at'] != null
        ? 'Published on: ${DateFormat('dd MMM, yyyy').format(DateTime.parse(notice['published_at']))}'
        : 'Date not available';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              publishedDate,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 32),
            HtmlWidget(
              content,
              textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5), // Improve line spacing for readability
            ),
          ],
        ),
      ),
    );
  }
}