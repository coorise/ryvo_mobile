import 'package:flutter/material.dart';

import 'package:ryvo/components/permissions/permissions_prompt.dart';
import 'package:ryvo/configs/portal_nav.dart';
import 'package:ryvo/lib/api_client.dart';

void schedulePermissionsPrompt(BuildContext context, PortalArea area) {
  if (apiClientTestMode) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (context.mounted) PermissionsPrompt.maybeShow(context, area);
    });
  });
}
