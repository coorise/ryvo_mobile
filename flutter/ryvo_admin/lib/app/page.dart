import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ryvo_admin/configs/const.dart';

/// Default entry — redirects to landing (mirrors web `/` → `/landing`).
class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go(Routes.landing);
    });
    return const SizedBox.shrink();
  }
}
