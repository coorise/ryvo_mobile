import 'package:flutter/material.dart';

import 'package:ryvo/components/update/update_prompt.dart';
import 'package:ryvo/lib/api_client.dart';

class UpdateCheckHost extends StatefulWidget {
  const UpdateCheckHost({super.key, required this.child});

  final Widget child;

  @override
  State<UpdateCheckHost> createState() => _UpdateCheckHostState();
}

class _UpdateCheckHostState extends State<UpdateCheckHost> {
  @override
  Widget build(BuildContext context) => widget.child;
}

void scheduleUpdatePrompt(BuildContext context) {
  if (apiClientTestMode) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (context.mounted) UpdatePrompt.maybeShow(context);
    });
  });
}
