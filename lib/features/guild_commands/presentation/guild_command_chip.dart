import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';

/// Fork: the `/name` chip after the timestamp of a message made by a server
/// command. Named by the server, so it stays right after a rename.
class GuildCommandChip extends StatelessWidget {
  const GuildCommandChip({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: context.colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '/$name', // i18n-ignore: a command's name, typed by its community.
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textStyles.timestamp.copyWith(
          color: context.colors.textLink,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
