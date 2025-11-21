import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:swim_apps_shared/support/support_detail.dart';

class SupportListPage extends StatelessWidget {
  final String userId;

  const SupportListPage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection("support_requests")
        .where("userId", isEqualTo: userId)
        .orderBy("createdAt", descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text("My Support Requests")),
      body: StreamBuilder(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint(snapshot.error.toString());
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text("You haven't submitted any support requests yet."),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data();
              final id = docs[i].id;

              final category = data["category"] ?? "";
              final message = data["message"] ?? "";
              final status = data["status"] ?? "open";
              //final created = (data["createdAt"] as Timestamp?)?.toDate();
              //final jiraTicket = data["jiraTicket"];

              return ListTile(
                title: Text(category),
                subtitle: Text(
                  message.length > 60
                      ? "${message.substring(0, 60)}…"
                      : message,
                ),
                trailing: Text(
                  status,
                  style: TextStyle(
                    color: status == "open"
                        ? Colors.orange
                        : status == "resolved"
                        ? Colors.green
                        : Colors.blue,
                  ),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SupportDetailPage(id: id, data: data),
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
