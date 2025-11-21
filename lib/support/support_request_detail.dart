import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportRequestDetailPage extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> data;

  const SupportRequestDetailPage({
    super.key,
    required this.requestId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final message = data['message'] as String? ?? '';
    final category = data['category'] as String? ?? 'Other';
    final status = data['status'] as String? ?? 'open';
    final attachments = (data['attachments'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final jiraTicket = data['jiraTicket'] as String?;
    final clientMeta = (data['clientMeta'] as Map<String, dynamic>? ?? {});
    final reportedForName = data['reportedForName'] as String?;
    final reportedForUserId = data['reportedForUserId'] as String?;

    return Scaffold(
      appBar: AppBar(title: Text('Request $requestId')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              'Category: $category',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Status: $status'),
            if (reportedForName != null)
              Text('Reported for: $reportedForName ($reportedForUserId)'),
            if (jiraTicket != null) ...[
              const SizedBox(height: 8),
              Text('Jira ticket: $jiraTicket'),
            ],
            const SizedBox(height: 16),
            Text('Message', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText(message),
            const SizedBox(height: 16),
            Text('Client info', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('App: ${clientMeta['appVersion'] ?? '-'}'),
            Text('Platform: ${clientMeta['platform'] ?? '-'}'),
            Text('Device: ${clientMeta['deviceModel'] ?? '-'}'),
            Text('OS: ${clientMeta['osVersion'] ?? '-'}'),
            const SizedBox(height: 16),
            if (attachments.isNotEmpty) ...[
              Text(
                'Attachments',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...attachments.map(
                (att) => ListTile(
                  leading: const Icon(Icons.attachment),
                  title: Text(att['name'] ?? 'file'),
                  onTap: () async {
                    final url = att['url'] as String?;
                    if (url == null) return;
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
