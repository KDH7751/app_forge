import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'feedback_controller.dart';
import 'feedback_dispatcher.dart';

/// feedback 중앙 controller provider.
final feedbackControllerProvider =
    NotifierProvider<FeedbackController, FeedbackState>(FeedbackController.new);

/// feature/app이 request를 전달할 때 쓰는 dispatcher provider.
final feedbackDispatcherProvider = Provider<FeedbackDispatcher>((ref) {
  return FeedbackDispatcher(ref.read(feedbackControllerProvider.notifier));
});
