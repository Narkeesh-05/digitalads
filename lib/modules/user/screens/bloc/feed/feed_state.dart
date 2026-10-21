abstract class FeedState {}

class FeedLoading extends FeedState {}

class FeedLoaded extends FeedState {
  final List<Map<String, dynamic>> ads;
  FeedLoaded(this.ads);
}

class FeedEmpty extends FeedState {}

class FeedError extends FeedState {
  final String message;
  FeedError(this.message);
}