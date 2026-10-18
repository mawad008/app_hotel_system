import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/presentation/form_submission.dart';
import '../../domain/entities/guest_profile.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

/// Drives the `إكمال البيانات` form. Auto-disposed: it only lives while the
/// screen is on top. The session it completes comes from
/// [AuthState.awaitingProfile].
class CompleteProfileController extends Notifier<FormSubmission> {
  @override
  FormSubmission build() => const FormSubmission.idle();

  Future<void> submit({required String fullName, required String email}) async {
    final AuthState auth = ref.read(authControllerProvider);
    if (auth is! AuthAwaitingProfile) return;

    state = const FormSubmission.inProgress();
    try {
      final AuthSession completed = await ref
          .read(authRepositoryProvider)
          .completeProfile(
            session: auth.session,
            fullName: fullName,
            email: email,
          );
      ref.read(authControllerProvider.notifier).onProfileCompleted(completed);
      state = const FormSubmission.idle();
    } catch (error) {
      state = FormSubmission.failed(ErrorMapper.toFailure(error));
    }
  }
}

final completeProfileControllerProvider =
    NotifierProvider.autoDispose<CompleteProfileController, FormSubmission>(
      CompleteProfileController.new,
    );
