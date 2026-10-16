import 'package:flutter/material.dart';

import '../localization/l10n.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_icons.dart';

/// The persistent four-tab bottom navigation — v2 Figma `Tab Bar`
/// (`Active` = Home / Bookings / Services / Account).
///
/// Drawn to the frame rather than via Material's `NavigationBar` (whose
/// indicator, sizing and label metrics differ):
///
/// * white bar, 1px `border/default` top hairline, a faint sideways shadow
///   (`#414141` @7%, blur 14.7);
/// * 4 / 8 / 4 / 10 padding, four equal cells;
/// * each cell: 6px top/bottom padding, 24px icon, 4px gap, 12px label;
/// * **selected** = Bold icon + Medium label in `text/primary`;
///   **unselected** = Linear icon + Regular label in `text/secondary`.
///
/// Below the bar sits the Figma `page footer`: white, 8px + the home-indicator
/// inset (only on devices that have a bottom inset). It never routes itself;
/// the host supplies [onSelected].
///
/// Android back on the Bookings, Services or Account tab returns to Home
/// (through [onSelected]) instead of closing the app; back on Home exits as
/// usual. Each tab is its own root route, so there is nothing to pop.
enum AppNavTab { home, bookings, services, account }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    required this.onSelected,
  });

  final AppNavTab current;
  final ValueChanged<AppNavTab> onSelected;

  /// Figma tab-bar shadow: `#414141` at 7%, blur 14.7, x-offset 1.
  static const BoxShadow _shadow = BoxShadow(
    color: Color(0x12414141),
    blurRadius: 14.7,
    offset: Offset(1, 0),
  );

  /// Figma `page footer` (42 on a 34pt-indicator phone): 8 + the inset.
  static double _footer(BuildContext context) {
    final double inset = MediaQuery.viewPaddingOf(context).bottom;
    return inset > 0 ? inset + 8 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AppColorTokens c = context.colors;

    Widget tab(AppNavTab t, IconData outline, IconData bold, String label) {
      return Expanded(
        child: _TabItem(
          label: label,
          icon: current == t ? bold : outline,
          selected: current == t,
          onTap: () => onSelected(t),
        ),
      );
    }

    // Only the `isFirst` aspect: depending on the whole route would rebuild
    // the bar every time a page is pushed over (or popped off) the shell.
    final bool isRootRoute = ModalRoute.isFirstOf(context) ?? true;
    return PopScope(
      canPop: current == AppNavTab.home || !isRootRoute,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) onSelected(AppNavTab.home);
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.bgSurface,
          border: Border(top: BorderSide(color: c.borderDefault)),
          boxShadow: const <BoxShadow>[_shadow],
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: _footer(context)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
            child: Row(
              children: <Widget>[
                tab(
                  AppNavTab.home,
                  AppIcons.tabHomeOutline,
                  AppIcons.tabHome,
                  l10n.navHome,
                ),
                tab(
                  AppNavTab.bookings,
                  AppIcons.tabBookingsOutline,
                  AppIcons.tabBookings,
                  l10n.navBookings,
                ),
                tab(
                  AppNavTab.services,
                  AppIcons.tabServicesOutline,
                  AppIcons.tabServices,
                  l10n.navServices,
                ),
                tab(
                  AppNavTab.account,
                  AppIcons.tabAccountOutline,
                  AppIcons.tabAccount,
                  l10n.navAccount,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColorTokens c = context.colors;
    final Color color = selected ? c.textPrimary : c.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                // 12px label on a 15px line (the Figma text box).
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  height: 15 / 12,
                  fontWeight: selected
                      ? AppTypography.medium
                      : AppTypography.regular,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
