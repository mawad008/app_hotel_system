import 'package:flutter/material.dart';

import '../../../../core/widgets/bottom_action_bar.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/pull_to_refresh.dart';

/// The shell every `PROFILE_*` sub-screen shares (12 · Notifications &
/// profile): app bar, an info [InfoBanner], the list cards 18px apart on a
/// 24px page inset, and one pinned footer action.
class ProfileSubpage extends StatelessWidget {
  const ProfileSubpage({
    super.key,
    required this.title,
    required this.bannerTitle,
    required this.bannerMessage,
    required this.cards,
    this.bannerTone = InfoBannerTone.info,
    this.footer,
    this.onRefresh,
  });

  final String title;
  final String bannerTitle;
  final String bannerMessage;
  final InfoBannerTone bannerTone;
  final List<Widget> cards;

  /// The pinned primary action (a PrimaryButton), if any.
  final Widget? footer;

  /// Pull-to-refresh: refetches the data the page shows, if any.
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final Widget list = ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        InfoBanner(
          tone: bannerTone,
          title: bannerTitle,
          message: bannerMessage,
        ),
        for (final Widget card in cards) ...<Widget>[
          const SizedBox(height: 18),
          card,
        ],
      ],
    );
    return Scaffold(
      appBar: HotelAppBar(title: title),
      body: SafeArea(
        child: onRefresh == null
            ? list
            : PullToRefresh(onRefresh: onRefresh!, child: list),
      ),
      bottomNavigationBar: footer == null
          ? null
          : BottomActionBar.actions(primary: footer!),
    );
  }
}
