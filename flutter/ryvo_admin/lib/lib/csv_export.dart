import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showCsvExportDialog(
  BuildContext context, {
  required String title,
  required String csv,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SelectableText(csv, style: const TextStyle(fontSize: 12)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        FilledButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: csv));
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard.')),
              );
            }
          },
          child: const Text('Copy CSV'),
        ),
      ],
    ),
  );
}

String rowsToCsv(
  List<Map<String, dynamic>> rows,
  List<String> columns, {
  List<String Function(Map<String, dynamic> row)>? getters,
}) {
  final header = columns.join(',');
  final lines = rows.map((row) {
    if (getters != null) {
      return getters.map((g) => _escape(g(row))).join(',');
    }
    return columns.map((c) => _escape(row[c]?.toString() ?? '')).join(',');
  });
  return '$header\n${lines.join('\n')}';
}

String _escape(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}

Future<void> showTextExportDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showCsvExportDialog(context, title: title, csv: body);
}
