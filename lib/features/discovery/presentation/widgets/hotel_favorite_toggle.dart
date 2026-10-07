import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../authentication/presentation/state/login_flow_controller.dart';
import '../../../authentication/presentation/state/post_auth_redirect_controller.dart';
import '../state/favorite_hotels_controller.dart';

/// One heart tap, shared by Hotel Detail, Room Detail and the favourites list.
///
/// A signed-out guest is sent to sign-in and returns to the current screen.
/// Otherwise the outcome is confirmed in a snackbar — "saved" offers a way to
/// the favourites list (so the heart never leads nowhere), "removed" offers
/// undo — and a failed write is reported.
Future<void> toggleHotelFavorite(
  BuildContext context,
  WidgetRef ref,
  String hotelId, {
  bool offerViewAction = true,
}) async {
  final AppLocalizations l10n = context.l10n;
  final GoRouter router = GoRouter.of(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final String here = GoRouterState.of(context).uri.toString();
  final FavoriteHotelsController favorites = ref.read(favoriteHotelsProvider.notifier);

  try {
    final FavoriteToggleOutcome outcome = await favorites.toggle(hotelId);
    switch (outcome) {
      case FavoriteToggleOutcome.signInRequired:
        ref.read(postAuthRedirectProvider.notifier).remember(here);
        ref.read(loginFlowControllerProvider.notifier).reset();
        router.goNamed(AppRoutes.signInName);
      case FavoriteToggleOutcome.saved:
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.favoriteSavedSnack),
              action: offerViewAction
                  ? SnackBarAction(
                      label: l10n.favoriteViewAction,
                      onPressed: () => router.pushNamed(AppRoutes.favoriteHotelsName),
                    )
                  : null,
            ),
          );
      case FavoriteToggleOutcome.removed:
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(l10n.favoriteRemovedSnack),
              action: SnackBarAction(
                label: l10n.favoriteUndoAction,
                onPressed: () async {
                  try {
                    await favorites.toggle(hotelId);
                  } on Failure catch (failure) {
                    messenger.showSnackBar(
                      SnackBar(content: Text(failure.localizedMessage(l10n))),
                    );
                  }
                },
              ),
            ),
          );
    }
  } on Failure catch (failure) {
    messenger
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(failure.localizedMessage(l10n))));
  }
}
