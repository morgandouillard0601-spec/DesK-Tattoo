import 'package:flutter/material.dart';

/// A scrollable bottom-sheet scaffold with a sticky header (title + close)
/// and a sticky footer (save button). Designed for create/edit forms.
class FormSheetScaffold extends StatelessWidget {
  const FormSheetScaffold({
    required this.title,
    required this.child,
    required this.onSave,
    this.saveLabel = 'Enregistrer',
    this.canSave = true,
    super.key,
  });

  final String title;
  final Widget child;
  final VoidCallback onSave;
  final String saveLabel;
  final bool canSave;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (BuildContext context, ScrollController controller) {
          return Column(
            children: <Widget>[
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  children: <Widget>[child],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: FilledButton(
                    onPressed: canSave ? onSave : null,
                    child: Text(saveLabel),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
