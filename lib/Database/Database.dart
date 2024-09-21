
class FeedbackData {
  final String id;
  final Map<String, double> location;
  final String category;

  final String comments;
  final DateTime timestamp;

  FeedbackData(
      {required this.id,
      required this.location,
      required this.category,
      required this.comments,
      required this.timestamp});

  factory FeedbackData.fromJson(Map<String, dynamic> feedback) {
    return FeedbackData(
      id: feedback['_id'],
      location: {
        'latitude': feedback['location']['latitude'].toDouble(),
        'longitude': feedback['location']['longitude'].toDouble(),
      },
      category: feedback['category'],
      comments: feedback['comment'],
      timestamp: DateTime.tryParse(feedback['timestamp'] ?? '') ?? DateTime.now(),
    );
  }
}
