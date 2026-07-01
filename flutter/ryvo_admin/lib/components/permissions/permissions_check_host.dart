import 'package:flutter/material.dart';

import 'package:ryvo_admin/components/permissions/permissions_prompt.dart';

void schedulePermissionsPrompt(BuildContext context) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (context.mounted) PermissionsPrompt.maybeShow(context);
    });
  });
}
