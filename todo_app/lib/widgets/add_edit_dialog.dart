import 'package:flutter/material.dart';

/// A simple title-only add/edit dialog. Returns the trimmed text, or
/// null if the user cancelled / left it empty.
Future<String?> showTitleDialog(
  BuildContext context, {
  required String heading,
  String initialValue = '',
  String hint = 'Title',
  String confirmLabel = 'Save',
}) async {
  final controller = TextEditingController(text: initialValue);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(heading),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final v = controller.text.trim();
            if (v.isNotEmpty) Navigator.pop(context, v);
          },
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// Add/edit dialog with an optional description field, used by Normal Tasks.
Future<Map<String, String>?> showTitleDescriptionDialog(
  BuildContext context, {
  required String heading,
  String initialTitle = '',
  String initialDescription = '',
}) async {
  final titleController = TextEditingController(text: initialTitle);
  final descController = TextEditingController(text: initialDescription);
  return showDialog<Map<String, String>>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(heading),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Description (optional)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final t = titleController.text.trim();
            if (t.isNotEmpty) {
              Navigator.pop(context, {'title': t, 'description': descController.text.trim()});
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
