import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:swim_apps_shared/objects/user/coach.dart';
import 'package:swim_apps_shared/objects/user/user.dart';
import 'package:swim_apps_shared/support/support_list.dart';

import 'support_controller.dart';

class SupportPage extends StatelessWidget {
  final AppUser user;
  final bool isAccountHolder;
  final List<Coach> coaches;

  const SupportPage({
    super.key,
    required this.user,
    this.isAccountHolder = false,
    this.coaches = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SupportController(
        user: user,
        isAccountHolder: isAccountHolder,
        coaches: coaches,
      ),
      child: const _SupportPageView(),
    );
  }
}

class _SupportPageView extends StatelessWidget {
  const _SupportPageView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SupportController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Support"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SupportListPage(userId: c.user.id),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // CATEGORY
            DropdownButtonFormField<String>(
              initialValue: c.selectedCategory,
              items: c.categories
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                if (v != null) c.setCategory(v);
              },
              decoration: const InputDecoration(
                labelText: "Category",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // ON BEHALF OF
            if (c.canReportForOthers)
              Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: c.reportedForUserId,
                    decoration: const InputDecoration(
                      labelText: 'Who is this about?',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: c.user.id,
                        child: Text('Me (${c.user.name})'),
                      ),
                      ...c.coaches.map(
                        (coach) => DropdownMenuItem(
                          value: coach.id,
                          child: Text(coach.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => c.selectReportedUser(v!),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.format_bold),
                  onPressed: () => c.wrapSelection('**', '**'),
                ),
                IconButton(
                  icon: const Icon(Icons.format_list_bulleted),
                  onPressed: c.insertBullet,
                ),
                IconButton(
                  icon: const Icon(Icons.code),
                  onPressed: () => c.wrapSelection('`', '`'),
                ),
              ],
            ),

            // MESSAGE FIELD
            Expanded(
              child: TextField(
                controller: c.messageController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: "Describe your issue, steps to reproduce, etc.",
                ),
              ),
            ),

            const SizedBox(height: 12),

            // SEND BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: c.loading
                    ? null
                    : () async {
                        final error = await c.sendSupportRequest();
                        if (error == null) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Support request sent!"),
                              ),
                            );
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text(error)));
                          }
                        }
                      },
                icon: c.loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: const Text("Send to Support"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
