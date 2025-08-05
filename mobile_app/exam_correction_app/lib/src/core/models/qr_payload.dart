import 'package:equatable/equatable.dart';

class QrPayload extends Equatable {
  final String assessmentId;
  final String teacherId;
  final String issuedAt;
  final String? expiresAt;
  final List<String> answerKey;
  final Map<String, int> pointValues;
  final int questionCount;
  final String assessmentName;

  const QrPayload({
    required this.assessmentId,
    required this.teacherId,
    required this.issuedAt,
    required this.answerKey,
    required this.pointValues,
    required this.questionCount,
    required this.assessmentName,
    this.expiresAt,
  });

  factory QrPayload.fromJson(Map<String, dynamic> json) {
    return QrPayload(
      assessmentId: json['assessmentId'] as String,
      teacherId: json['teacherId'] as String,
      issuedAt: json['issuedAt'] as String,
      expiresAt: json['expiresAt'] as String?,
      answerKey: List<String>.from(json['answerKey'] as List),
      pointValues: Map<String, int>.from(json['pointValues'] as Map),
      questionCount: json['questionCount'] as int,
      assessmentName: json['assessmentName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'assessmentId': assessmentId,
      'teacherId': teacherId,
      'issuedAt': issuedAt,
      'expiresAt': expiresAt,
      'answerKey': answerKey,
      'pointValues': pointValues,
      'questionCount': questionCount,
      'assessmentName': assessmentName,
    };
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    try {
      final expiryDate = DateTime.parse(expiresAt!);
      return DateTime.now().isAfter(expiryDate);
    } catch (e) {
      return false;
    }
  }

  @override
  List<Object?> get props => [
        assessmentId,
        teacherId,
        issuedAt,
        expiresAt,
        answerKey,
        pointValues,
        questionCount,
        assessmentName,
      ];
}