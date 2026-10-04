part of 'guild_sidebar.dart';

// Fork: adds the quick switcher button from outside upstream's build, so
// upstream's sidebar stays as upstream has it.

class _ForkGuildSidebarState extends _GuildSidebarState {
  @override
  Widget build(BuildContext context) {
    final Widget sidebar = super.build(context);
    if (!isMobileLayout(context)) {
      return sidebar;
    }
    return Stack(
      // Gives the sidebar the constraints it has without the button.
      fit: StackFit.passthrough,
      children: [
        sidebar,
        const Positioned(right: 16, bottom: 16, child: QuickSwitcherFab()),
      ],
    );
  }
}
