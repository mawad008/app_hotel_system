import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../authentication/presentation/state/login_flow_controller.dart';
import '../../../authentication/presentation/state/post_auth_redirect_controller.dart';
import '../../domain/entities/favorite_room.dart';
import '../state/favorite_hotels_controller.dart';
import '../state/favorite_rooms_controller.dart';

/// One hotel heart tap, shared by Hotel Detail and the favourites list.
Future<void> toggleHotelFavorite(
  BuildContext context,
  WidgetRef ref,
  String hotelId, {
  bool offerViewAction = true,
}) {
  final FavoriteHotelsController favorites = ref.read(favoriteHotelsProvider.notifier);
  return _toggleFavorite(
    context,
    ref,
    toggle: () => favorites.toggle(hotelId),
    savedMessage: context.l10n.favoriteSavedSnack,
    removedMessage: context.l10n.favoriteRemovedSnack,
    offerViewAction: offerViewAction,
  );
}

/// One room heart tap, shared by Room Detail and the favourites list.
Future<void> toggleRoomFavorite(
  BuildContext context,
  WidgetRef ref,
  FavoriteRoom room, {
  bool offerViewAction = true,
}) {
  final FavoriteRoomsController favorites = ref.read(favoriteRoomsProvider.notifier);
  return _toggleFavorite(
    context,
    ref,
    toggle: () => favorites.toggle(room),
    savedMessage: context.l10n.favoriteRoomSavedSnack,
    removedMessage: context.l10n.favoriteRoomRemovedSnack,
    offerViewAction: offerViewAction,
  );
}

/// A signed-out guest is sent to sign-in and returns to the current screen.
/// Otherwise the outcome is confirmed in a snackbar — "saved" offers a way to
/// the favourites list (so the heart never leads nowhere), "removed" offers
/// undo — and a failed write is reported.
Future<void> _toggleFavorite(
  BuildContext context,
  WidgetRef ref, {
  required Future<FavoriteToggleOutcome> Function() toggle,
  required String savedMessage,
  required String removedMessage,
  required bool offerViewAction,
}) async {
  final AppLocalizations l10n = context.l10n;
  final GoRouter router = GoRouter.of(context);
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  final String here = GoRouterState.of(context).uri.toString();

  try {
    final FavoriteToggleOutcome outcome = await toggle();
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
              content: Text(savedMessage),
              action: offerViewAction
                  ? SnackBarAction(
                      label: l10n.favoriteViewAction,
                      onPressed: () => router.pushNamed(AppRoutes.favoritesName),
                    )
                  : null,
            ),
          );
      case FavoriteToggleOutcome.removed:
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(removedMessage),
              action: SnackBarAction(
                label: l10n.favoriteUndoAction,
                onPressed: () async {
                  try {
                    await toggle();
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
