import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../objects/user/coach.dart';
import '../../objects/user/user.dart';
import '../support_controller.dart';

Future<void> showSupportModal(
  BuildContext context, {
  required AppUser user,
  bool isAccountHolder = false,
  List<Coach> coaches = const [],
}) {
  return showModalBottomSheet(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) {
      return ChangeNotifierProvider(
        create: (_) => SupportController(
          user: user,
          isAccountHolder: isAccountHolder,
          coaches: coaches,
        ),
        child: const SupportModalView(),
      );
    },
  );
}

class SupportModalView extends StatelessWidget {
  const SupportModalView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<SupportController>();
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- GRAB HANDLE ---
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          Text(
            "Contact Support",
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // CATEGORY
          DropdownButtonFormField<String>(
            initialValue: c.selectedCategory,
            items: c.categories
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => c.setCategory(v!),
            decoration: const InputDecoration(
              labelText: "Category",
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          // REPORT ON BEHALF OF
          if (c.canReportForOthers) ...[
            DropdownButtonFormField<String>(
              initialValue: c.reportedForUserId,
              decoration: const InputDecoration(
                labelText: "Who is this about?",
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: c.user.id,
                  child: Text("Me (${c.user.name})"),
                ),
                ...c.coaches.map(
                  (coach) => DropdownMenuItem(
                      value: coach.id, child: Text(coach.name)),
                )
              ],
              onChanged: (v) => c.selectReportedUser(v!),
            ),
            const SizedBox(height: 12),
          ],

          // RICH TEXT TOOLS
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

          // MESSAGE
          SizedBox(
            height: 200,
            child: TextField(
              controller: c.messageController,
              maxLines: null,
              expands: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Describe your issue…",
              ),
            ),
          ),

          const SizedBox(height: 16),

          // SEND BUTTON
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error)),
                          );
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
    );
  }
}
