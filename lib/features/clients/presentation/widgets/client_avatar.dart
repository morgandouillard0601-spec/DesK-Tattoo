import 'package:flutter/material.dart';

import '../../domain/client.dart';

class ClientAvatar extends StatelessWidget {
  const ClientAvatar({required this.client, this.size = 44, super.key});

  final Client client;
  final double size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color bg = _colorFromName(client.fullName, theme.colorScheme);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bg,
      child: Text(
        client.initials,
        style: TextStyle(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.38,
        ),
      ),
    );
  }

  static Color _colorFromName(String name, ColorScheme scheme) {
    final List<Color> palette = <Color>[
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.primaryFixedDim,
      scheme.error,
    ];
    final int hash = name.codeUnits.fold<int>(0, (int a, int b) => a + b);
    return palette[hash % palette.length];
  }
}
