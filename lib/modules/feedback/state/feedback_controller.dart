import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/feedback_request.dart';
import '../domain/feedback_slots.dart';

/// feedback queue, dedupe, priority, lifecycle를 관리하는 중앙 state.
class FeedbackState {
  const FeedbackState({
    this.queue = const <FeedbackRequest>[],
    this.activeByChannel = const <FeedbackChannel, FeedbackRequest>{},
  });

  final List<FeedbackRequest> queue;
  final Map<FeedbackChannel, FeedbackRequest> activeByChannel;

  FeedbackRequest? activeFor(FeedbackChannel channel) =>
      activeByChannel[channel];

  FeedbackState copyWith({
    List<FeedbackRequest>? queue,
    Map<FeedbackChannel, FeedbackRequest>? activeByChannel,
  }) {
    return FeedbackState(
      queue: queue ?? this.queue,
      activeByChannel: activeByChannel ?? this.activeByChannel,
    );
  }
}

/// feedback display 정책을 적용하는 controller.
class FeedbackController extends Notifier<FeedbackState> {
  @override
  FeedbackState build() {
    return const FeedbackState();
  }

  void dispatch(FeedbackRequest request) {
    if (_hasDuplicate(request)) {
      return;
    }

    final nextActiveByChannel = Map<FeedbackChannel, FeedbackRequest>.from(
      state.activeByChannel,
    );
    final nextQueue = List<FeedbackRequest>.from(state.queue);
    final activeSameChannel = nextActiveByChannel[request.channel];

    if (_canActivateImmediately(
      request,
      activeSameChannel: activeSameChannel,
    )) {
      nextActiveByChannel[request.channel] = request;
      state = state.copyWith(activeByChannel: nextActiveByChannel);
      return;
    }

    if (request.isBlocking) {
      final activeBlocking = _activeBlocking(nextActiveByChannel);

      if (activeBlocking != null &&
          _comparePriority(request.priority, activeBlocking.priority) > 0) {
        nextActiveByChannel.remove(activeBlocking.channel);
        nextActiveByChannel[request.channel] = request;
        state = state.copyWith(activeByChannel: nextActiveByChannel);
        return;
      }
    }

    nextQueue.add(request);
    state = state.copyWith(queue: nextQueue);
  }

  void complete(FeedbackChannel channel, String requestId) {
    final currentActive = state.activeByChannel[channel];

    if (currentActive == null || currentActive.id != requestId) {
      return;
    }

    final nextActiveByChannel = Map<FeedbackChannel, FeedbackRequest>.from(
      state.activeByChannel,
    )..remove(channel);
    final nextQueue = List<FeedbackRequest>.from(state.queue);
    final nextRequest = _takeNextRequest(
      queue: nextQueue,
      activeByChannel: nextActiveByChannel,
    );

    if (nextRequest != null) {
      nextActiveByChannel[nextRequest.channel] = nextRequest;
    }

    state = state.copyWith(
      queue: nextQueue,
      activeByChannel: nextActiveByChannel,
    );
  }

  bool _hasDuplicate(FeedbackRequest request) {
    final dedupeKey = request.dedupeKey;

    if (dedupeKey == null || dedupeKey.isEmpty) {
      return false;
    }

    for (final active in state.activeByChannel.values) {
      if (active.dedupeKey == dedupeKey) {
        return true;
      }
    }

    for (final queued in state.queue) {
      if (queued.dedupeKey == dedupeKey) {
        return true;
      }
    }

    return false;
  }

  bool _canActivateImmediately(
    FeedbackRequest request, {
    required FeedbackRequest? activeSameChannel,
  }) {
    if (activeSameChannel != null) {
      return false;
    }

    if (request.channel == FeedbackChannel.snackbar &&
        _activeBlocking(state.activeByChannel) != null) {
      return false;
    }

    if (request.isBlocking && _activeBlocking(state.activeByChannel) != null) {
      return false;
    }

    return true;
  }

  FeedbackRequest? _takeNextRequest({
    required List<FeedbackRequest> queue,
    required Map<FeedbackChannel, FeedbackRequest> activeByChannel,
  }) {
    for (var index = 0; index < queue.length; index++) {
      final candidate = queue[index];

      if (activeByChannel.containsKey(candidate.channel)) {
        continue;
      }

      if (candidate.channel == FeedbackChannel.snackbar &&
          _activeBlocking(activeByChannel) != null) {
        continue;
      }

      if (candidate.isBlocking && _activeBlocking(activeByChannel) != null) {
        continue;
      }

      queue.removeAt(index);
      return candidate;
    }

    return null;
  }

  FeedbackRequest? _activeBlocking(
    Map<FeedbackChannel, FeedbackRequest> activeByChannel,
  ) {
    return activeByChannel[FeedbackChannel.dialog] ??
        activeByChannel[FeedbackChannel.modalSheet];
  }

  int _comparePriority(FeedbackPriority left, FeedbackPriority right) {
    return left.index.compareTo(right.index);
  }
}
