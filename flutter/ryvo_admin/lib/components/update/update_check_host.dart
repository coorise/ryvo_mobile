import 'package:flutter/material.dart';

import 'package:ryvo_admin/components/update/update_prompt.dart';

/// Legacy wrapper — OTA prompt now runs from [LandingPage] where navigator context is ready.
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

/// Call from landing (logged out) or [AdminShell] (logged in) once the route is visible.
void scheduleUpdatePrompt(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (context.mounted) UpdatePrompt.maybeShow(context);
    });
  });
}
