import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:swim_apps_shared/objects/user/user.dart';
import 'package:swim_apps_shared/support/full_page_widget/support_request_detail.dart';

class MySupportRequestsPage extends StatelessWidget {
  final AppUser user;

  const MySupportRequestsPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('support_requests')
        .where('userId', isEqualTo: user.id)
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('My Support Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading requests'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('No support requests yet.'));
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final category = data['category'] ?? 'Other';
              final status = (data['status'] ?? 'open') as String;
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final jiraTicket = data['jiraTicket'] as String?;
              final message = (data['message'] ?? '') as String;

              return ListTile(
                title: Text(category),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (createdAt != null)
                      Text(
                        createdAt.toIso8601String().substring(0, 16),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (jiraTicket != null && jiraTicket.isNotEmpty)
                      Text(
                        'Jira: $jiraTicket',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                trailing: _StatusChip(status: status),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SupportRequestDetailPage(
                        requestId: doc.id,
                        data: data,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  Color _color(BuildContext context) {
    switch (status) {
      case 'open':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'waiting_for_user':
        return Colors.purple;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(status),
      backgroundColor: _color(context).withAlpha(15),
      labelStyle: TextStyle(color: _color(context)),
    );
  }
}
