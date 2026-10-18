import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure_l10n.dart';
import '../../../../core/localization/l10n.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/hotel_app_bar.dart';
import '../../../../core/widgets/info_banner.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/message_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../domain/entities/review.dart';
import '../../domain/entities/review_draft.dart';
import '../state/review_providers.dart';
import '../state/review_submission_controller.dart';
import '../widgets/rating_selector.dart';
import '../widgets/review_status_pill.dart';
import '../../domain/entities/review_category.dart';
import '../../../../core/widgets/app_icons.dart';

/// `05 · Depart & Invoice` — "كيف كانت إقامتك؟". Rate 1–5, add optional text,
/// submit. If a review already exists it is shown read-only. Eligibility is a
/// UX pre-check; the backend stays authoritative.
class ReviewFormPage extends ConsumerStatefulWidget {
  const ReviewFormPage({super.key, required this.reservationId});

  final String reservationId;

  @override
  ConsumerState<ReviewFormPage> createState() => _ReviewFormPageState();
}

class _ReviewFormPageState extends ConsumerState<ReviewFormPage> {
  final TextEditingController _text = TextEditingController();
  ReviewDraft _draft = const ReviewDraft();
  bool _showRatingError = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<ReviewContext> ctxAsync = ref.watch(
      reviewContextProvider(widget.reservationId),
    );
    final AsyncValue<Review?> reviewAsync = ref.watch(
      reservationReviewProvider(widget.reservationId),
    );

    return Scaffold(
      appBar: HotelAppBar(title: l10n.reviewFormTitle),
      body: SafeArea(
        child: _merge(
          ctxAsync,
          reviewAsync,
          loading: () =>
              Center(child: LoadingView(label: l10n.stateLoadingTitle)),
          error: (Object e) => MessageView(
            icon: AppIcons.review,
            title: l10n.reviewUnavailableTitle,
            message: ErrorMapper.toFailure(e).localizedMessage(l10n),
            actionLabel: l10n.actionRetry,
            onAction: () {
              ref.invalidate(reviewContextProvider(widget.reservationId));
              ref.invalidate(reservationReviewProvider(widget.reservationId));
            },
          ),
          data: (ReviewContext ctx, Review? review) {
            if (review != null) return _ExistingReview(review: review);
            if (!ctx.eligibility.canReview) {
              return MessageView(
                icon: AppIcons.review,
                title: l10n.reviewNotEligibleTitle,
                message: l10n.reviewNotEligibleBody,
                actionLabel: l10n.commonBack,
                onAction: () => context.pop(),
              );
            }
            return _Form(
              reservationId: widget.reservationId,
              draft: _draft,
              textController: _text,
              showRatingError: _showRatingError,
              onRating: (int r) => setState(() {
                _draft = _draft.copyWith(rating: r);
                _showRatingError = false;
              }),
              onText: (String t) => _draft = _draft.copyWith(text: t),
              onCategoryRating: (String id, int r) =>
                  setState(() => _draft = _draft.withCategoryRating(id, r)),
              onSubmit: () {
                if (!_draft.canSubmit) {
                  setState(() => _showRatingError = true);
                  return;
                }
                ref
                    .read(reviewSubmissionControllerProvider.notifier)
                    .submit(widget.reservationId, _draft);
                context.pushNamed(
                  AppRoutes.reviewProcessingName,
                  pathParameters: <String, String>{
                    'reservationId': widget.reservationId,
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  static Widget _merge(
    AsyncValue<ReviewContext> a,
    AsyncValue<Review?> b, {
    required Widget Function() loading,
    required Widget Function(Object) error,
    required Widget Function(ReviewContext, Review?) data,
  }) {
    if (a.hasError) return error(a.error!);
    if (b.hasError) return error(b.error!);
    if (a.hasValue && b.hasValue) return data(a.requireValue, b.requireValue);
    return loading();
  }
}

class _Form extends ConsumerWidget {
  const _Form({
    required this.reservationId,
    required this.draft,
    required this.textController,
    required this.showRatingError,
    required this.onRating,
    required this.onText,
    required this.onCategoryRating,
    required this.onSubmit,
  });

  final String reservationId;
  final ReviewDraft draft;
  final TextEditingController textController;
  final bool showRatingError;
  final ValueChanged<int> onRating;
  final ValueChanged<String> onText;
  final void Function(String categoryId, int rating) onCategoryRating;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final ReviewActionState action = ref.watch(
      reviewSubmissionControllerProvider,
    );
    final bool submitting =
        action is ReviewSubmitting &&
        action.request.reservationId == reservationId;
    // The hotel's dynamic review categories. Optional: while loading, on
    // error, or when the hotel defines none, the form is just the overall
    // rating + text.
    final List<ReviewCategory> categories =
        ref.watch(reviewCategoriesProvider(reservationId)).value ??
        const <ReviewCategory>[];

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: <Widget>[
              Text(l10n.reviewFormPrompt, style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  children: <Widget>[
                    RatingSelector(
                      rating: draft.rating,
                      onChanged: submitting ? null : onRating,
                    ),
                    if (showRatingError) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.reviewRatingRequired,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (categories.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        l10n.reviewCategoriesHeading,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        l10n.reviewCategoriesHint,
                        style: theme.textTheme.bodySmall,
                      ),
                      for (final ReviewCategory category
                          in categories) ...<Widget>[
                        const SizedBox(height: AppSpacing.sm),
                        _CategoryRatingRow(
                          category: category,
                          rating: draft.categoryRatings[category.id] ?? 0,
                          onChanged: submitting
                              ? null
                              : (int r) => onCategoryRating(category.id, r),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.reviewTextLabel,
                hintText: l10n.reviewTextHint,
                controller: textController,
                enabled: !submitting,
                onChanged: onText,
                textInputAction: TextInputAction.newline,
              ),
              if (action is ReviewSubmitFailed &&
                  action.request.reservationId == reservationId) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                InfoBanner(
                  tone: InfoBannerTone.error,
                  title: l10n.reviewUnavailableTitle,
                  message: action.failure.localizedMessage(l10n),
                ),
              ],
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.xs,
            AppSpacing.pageGutter,
            AppSpacing.md,
          ),
          child: PrimaryButton(
            label: submitting ? l10n.reviewSubmittingCta : l10n.reviewSubmitCta,
            isLoading: submitting,
            onPressed: submitting ? null : onSubmit,
          ),
        ),
      ],
    );
  }
}

class _ExistingReview extends StatelessWidget {
  const _ExistingReview({required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ThemeData theme = Theme.of(context);
    final MaterialLocalizations ml = MaterialLocalizations.of(context);

    return Column(
      children: <Widget>[
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: <Widget>[
              InfoBanner(
                tone: review.status.isPublished
                    ? InfoBannerTone.success
                    : review.status.isRejected
                    ? InfoBannerTone.error
                    : InfoBannerTone.info,
                title: review.status.isRejected
                    ? l10n.reviewRejectedTitle
                    : l10n.reviewAlreadyTitle,
                message: review.status.isRejected
                    ? l10n.reviewRejectedBody
                    : review.status.isPublished
                    ? l10n.reviewPublishedBody
                    : l10n.reviewPendingModerationBody,
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            l10n.reviewYourRatingLabel,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        ReviewStatusPill(status: review.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    RatingDisplay(rating: review.rating, size: 24),
                    for (final ReviewCategoryRating cr
                        in review.categoryRatings) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              cr.label,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          RatingDisplay(rating: cr.rating, size: 16),
                        ],
                      ),
                    ],
                    if (review.hasText) ...<Widget>[
                      const Divider(height: AppSpacing.lg),
                      Text(review.text!, style: theme.textTheme.bodyMedium),
                    ],
                    if (review.createdAt != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        ml.formatMediumDate(review.createdAt!),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          minimum: const EdgeInsets.fromLTRB(
            AppSpacing.pageGutter,
            AppSpacing.xs,
            AppSpacing.pageGutter,
            AppSpacing.md,
          ),
          child: SecondaryButton(
            label: l10n.reviewBackToReservation,
            onPressed: () => context.pop(),
          ),
        ),
      ],
    );
  }
}

/// One dynamic review category: its label and a compact 1-5 star selector.
class _CategoryRatingRow extends StatelessWidget {
  const _CategoryRatingRow({
    required this.category,
    required this.rating,
    required this.onChanged,
  });

  final ReviewCategory category;
  final int rating;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            category.label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        RatingSelector(rating: rating, onChanged: onChanged, size: 28),
      ],
    );
  }
}
