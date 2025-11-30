import 'package:flutter/material.dart';

class SupportDetailPage extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;

  const SupportDetailPage({super.key, required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    final attachments = data["attachments"] ?? [];
    final jiraTicket = data["jiraTicket"];

    return Scaffold(
      appBar: AppBar(title: Text("Request #$id")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              "Category: ${data['category']}",
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),

            Text(
              "Status: ${data['status']}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),

            if (jiraTicket != null)
              Text(
                "Jira Ticket: $jiraTicket",
                style: const TextStyle(fontSize: 16),
              ),
            if (jiraTicket != null) const SizedBox(height: 8),

            const Divider(),
            const Text("Message:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(data["message"] ?? ""),
            const SizedBox(height: 20),

            if (attachments.isNotEmpty) ...[
              const Divider(),
              const Text("Attachments:", style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              ...attachments.map<Widget>((a) {
                return ListTile(
                  leading: const Icon(Icons.attach_file),
                  title: Text(a["name"]),
                  onTap: () {
                    // open URL in browser
                  },
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}
