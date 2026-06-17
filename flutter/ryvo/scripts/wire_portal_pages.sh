#!/usr/bin/env bash
# Wire portal pages to panel implementations.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$ROOT/lib/app"

write_page() {
  local path="$1"
  local title_key="$2"
  local subtitle_key="$3"
  local panel_widget="$4"
  local expand="${5:-false}"
  local extra_import="${6:-}"

  mkdir -p "$(dirname "$path")"
  cat > "$path" <<EOF
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
import 'package:ryvo/components/portal/panels/${panel_widget}.dart';
import 'package:ryvo/configs/portal_nav.dart';
${extra_import}

class $(basename "$path" .dart | sed -E 's/(^|_)([a-z])/\U\2/g;s/_//g') extends ConsumerWidget {
  const $(basename "$path" .dart | sed -E 's/(^|_)([a-z])/\U\2/g;s/_//g')({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PortalPageShell(
      titleKey: '$title_key',
      subtitleKey: ${subtitle_key:+null}${subtitle_key:+'$subtitle_key'},
      expand: $expand,
      child: ${panel_widget.split('_').map({ echo "\${line^}"; } | tr -d '\n' | sed 's/Portal/Portal/')}(),
    );
  }
}
EOF
}

# Simpler: use python for page generation
python3 <<'PY'
from pathlib import Path

root = Path("/home/iautec/Projects/Web/Ryvo/ryvo/client/mobile/flutter/ryvo/lib/app")

def pascal(name: str) -> str:
    return "".join(w.capitalize() for w in name.replace(".dart", "").split("_"))

def write(path: Path, class_name: str, title: str, subtitle: str | None, panel_expr: str, expand=False, imports=None):
    imports = imports or []
    imp = "\n".join(f"import '{i}';" for i in imports)
    sub = f"'{subtitle}'" if subtitle else "null"
    content = f"""import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ryvo/components/portal/portal_page_shell.dart';
{imp}

class {class_name} extends ConsumerWidget {{
  const {class_name}({{super.key}});

  @override
  Widget build(BuildContext context, WidgetRef ref) {{
    return PortalPageShell(
      titleKey: '{title}',
      subtitleKey: {sub},
      expand: {str(expand).lower()},
      child: {panel_expr},
    );
  }}
}}
"""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)

panel = "package:ryvo/components/portal/panels"
nav = "package:ryvo/configs/portal_nav.dart"

pages = [
    ("driver/main/rides_page.dart", "DriverRidesPage", "portal.nav.rides", "portal.rides.subtitle", f"PortalRidesPanel(area: PortalArea.driver)", False, [f"{panel}/portal_rides_panel.dart", nav]),
    ("driver/main/clients_page.dart", "DriverClientsPage", "portal.nav.clients", "portal.clients.subtitle", f"PortalCounterpartiesPanel(area: PortalArea.driver)", False, [f"{panel}/portal_counterparties_panel.dart", nav]),
    ("driver/main/live_map_page.dart", "DriverLiveMapPage", "portal.nav.liveMap", None, f"PortalLiveMapPanel(area: PortalArea.driver)", True, [f"{panel}/portal_live_map_panel.dart", nav]),
    ("driver/main/kyc_page.dart", "DriverKycPage", "portal.nav.driverKyc", "portal.kyc.subtitle", "const PortalKycPanel()", True, [f"{panel}/portal_kyc_panel.dart"]),
    ("driver/communication/notifications_page.dart", "DriverNotificationsPage", "portal.nav.notifications", None, "const PortalNotificationsPanel()", False, [f"{panel}/portal_notifications_panel.dart"]),
    ("driver/communication/chat_page.dart", "DriverChatPage", "portal.nav.chat", None, "const PortalEphemeralChatPanel()", False, [f"{panel}/portal_chat_panel.dart"]),
    ("driver/communication/messages_page.dart", "DriverMessagesPage", "portal.nav.messages", None, "const PortalMessagesPanel()", False, [f"{panel}/portal_messages_panel.dart"]),
    ("driver/communication/chat_support_page.dart", "DriverChatSupportPage", "portal.nav.chatSupport", None, "const PortalChatSupportPanel()", False, [f"{panel}/portal_chat_support_panel.dart"]),
    ("driver/hr/feedbacks_page.dart", "DriverFeedbacksPage", "portal.nav.feedbacks", None, f"PortalFeedbacksPanel(area: PortalArea.driver)", False, [f"{panel}/portal_feedbacks_panel.dart", nav]),
    ("driver/finances/payments_page.dart", "DriverPaymentsPage", "portal.nav.payments", "portal.payments.subtitle", "const PortalPaymentsPanel()", False, [f"{panel}/portal_payments_panel.dart"]),
    ("driver/audits/analytics_page.dart", "DriverAnalyticsPage", "portal.nav.analytics", None, f"PortalAnalyticsPanel(area: PortalArea.driver)", False, [f"{panel}/portal_analytics_panel.dart", nav]),
    ("driver/audits/activity_logs_page.dart", "DriverActivityLogsPage", "portal.nav.activityLogs", None, "const PortalActivityLogsPanel()", False, [f"{panel}/portal_activity_logs_panel.dart"]),
    ("driver/audits/security_logs_page.dart", "DriverSecurityLogsPage", "portal.nav.securityLogs", None, "const PortalSecurityLogsPanel()", False, [f"{panel}/portal_security_logs_panel.dart"]),
    ("driver/settings/profile_page.dart", "DriverProfilePage", "portal.nav.profile", None, f"PortalProfilePanel(area: PortalArea.driver)", False, [f"{panel}/portal_profile_panel.dart", nav]),
    ("driver/settings/configurations_page.dart", "DriverConfigurationsPage", "portal.nav.configurations", None, f"PortalConfigurationsPanel(area: PortalArea.driver)", True, [f"{panel}/portal_configurations_panel.dart", nav]),

    ("client/main/rides_page.dart", "ClientRidesPage", "portal.nav.rides", "portal.rides.subtitle", f"PortalRidesPanel(area: PortalArea.client)", False, [f"{panel}/portal_rides_panel.dart", nav]),
    ("client/main/drivers_page.dart", "ClientDriversPage", "portal.nav.drivers", "portal.drivers.subtitle", f"PortalCounterpartiesPanel(area: PortalArea.client)", False, [f"{panel}/portal_counterparties_panel.dart", nav]),
    ("client/main/live_map_page.dart", "ClientLiveMapPage", "portal.nav.liveMap", None, f"PortalLiveMapPanel(area: PortalArea.client)", True, [f"{panel}/portal_live_map_panel.dart", nav]),
    ("client/communication/notifications_page.dart", "ClientNotificationsPage", "portal.nav.notifications", None, "const PortalNotificationsPanel()", False, [f"{panel}/portal_notifications_panel.dart"]),
    ("client/communication/chat_page.dart", "ClientChatPage", "portal.nav.chat", None, "const PortalEphemeralChatPanel()", False, [f"{panel}/portal_chat_panel.dart"]),
    ("client/communication/chat_support_page.dart", "ClientChatSupportPage", "portal.nav.chatSupport", None, "const PortalChatSupportPanel()", False, [f"{panel}/portal_chat_support_panel.dart"]),
    ("client/hr/feedbacks_page.dart", "ClientFeedbacksPage", "portal.nav.feedbacks", None, f"PortalFeedbacksPanel(area: PortalArea.client)", False, [f"{panel}/portal_feedbacks_panel.dart", nav]),
    ("client/finances/payments_page.dart", "ClientPaymentsPage", "portal.nav.payments", "portal.payments.subtitle", "const PortalPaymentsPanel()", False, [f"{panel}/portal_payments_panel.dart"]),
    ("client/audits/analytics_page.dart", "ClientAnalyticsPage", "portal.nav.analytics", None, f"PortalAnalyticsPanel(area: PortalArea.client)", False, [f"{panel}/portal_analytics_panel.dart", nav]),
    ("client/audits/activity_logs_page.dart", "ClientActivityLogsPage", "portal.nav.activityLogs", None, "const PortalActivityLogsPanel()", False, [f"{panel}/portal_activity_logs_panel.dart"]),
    ("client/audits/security_logs_page.dart", "ClientSecurityLogsPage", "portal.nav.securityLogs", None, "const PortalSecurityLogsPanel()", False, [f"{panel}/portal_security_logs_panel.dart"]),
    ("client/settings/profile_page.dart", "ClientProfilePage", "portal.nav.profile", None, f"PortalProfilePanel(area: PortalArea.client)", False, [f"{panel}/portal_profile_panel.dart", nav]),
    ("client/settings/configurations_page.dart", "ClientConfigurationsPage", "portal.nav.configurations", None, f"PortalConfigurationsPanel(area: PortalArea.client)", True, [f"{panel}/portal_configurations_panel.dart", nav]),
]

for rel, cls, title, sub, expr, expand, imps in pages:
    write(root / rel, cls, title, sub, expr, expand, imps)
    print("updated", rel)

# KYC car subpages
for rel, cls in [
    ("driver/main/kyc/cars/new_car_page.dart", "DriverNewCarPage"),
    ("driver/main/kyc/cars/car_detail_page.dart", "DriverCarDetailPage"),
    ("driver/main/kyc/cars/edit_car_page.dart", "DriverEditCarPage"),
]:
    write(root / rel, cls, "portal.nav.driverKyc", "portal.kyc.subtitle", "const PortalKycPanel()", True, [f"{panel}/portal_kyc_panel.dart"])
    print("updated", rel)
PY
