import 'package:hive/hive.dart';
import 'package:equatable/equatable.dart';

part 'corrected_exam.g.dart';

@HiveType(typeId: 0)
class CorrectedExam extends Equatable {
  @HiveField(0)
  final String examId;

  @HiveField(1)
  final String assessmentId;

  @HiveField(2)
  final String? studentIdentifier;

  @HiveField(3)
  final DateTime scanTimestamp;

  @HiveField(4)
  final List<String> studentAnswers;

  @HiveField(5)
  final List<String> correctAnswers;

  @HiveField(6)
  final List<int> scores;

  @HiveField(7)
  final double finalGrade;

  @HiveField(8)
  final String? imagePath;

  @HiveField(9)
  final bool isSynced;

  @HiveField(10)
  final String assessmentName;

  @HiveField(11)
  final Map<String, int> pointValues;

  const CorrectedExam({
    required this.examId,
    required this.assessmentId,
    required this.scanTimestamp,
    required this.studentAnswers,
    required this.correctAnswers,
    required this.scores,
    required this.finalGrade,
    required this.assessmentName,
    required this.pointValues,
    this.studentIdentifier,
    this.imagePath,
    this.isSynced = false,
  });

  CorrectedExam copyWith({
    String? examId,
    String? assessmentId,
    String? studentIdentifier,
    DateTime? scanTimestamp,
    List<String>? studentAnswers,
    List<String>? correctAnswers,
    List<int>? scores,
    double? finalGrade,
    String? imagePath,
    bool? isSynced,
    String? assessmentName,
    Map<String, int>? pointValues,
  }) {
    return CorrectedExam(
      examId: examId ?? this.examId,
      assessmentId: assessmentId ?? this.assessmentId,
      studentIdentifier: studentIdentifier ?? this.studentIdentifier,
      scanTimestamp: scanTimestamp ?? this.scanTimestamp,
      studentAnswers: studentAnswers ?? this.studentAnswers,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      scores: scores ?? this.scores,
      finalGrade: finalGrade ?? this.finalGrade,
      imagePath: imagePath ?? this.imagePath,
      isSynced: isSynced ?? this.isSynced,
      assessmentName: assessmentName ?? this.assessmentName,
      pointValues: pointValues ?? this.pointValues,
    );
  }

  int get totalQuestions => correctAnswers.length;
  
  int get correctCount => scores.where((score) => score > 0).length;
  
  double get percentageScore => totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0;

  @override
  List<Object?> get props => [
        examId,
        assessmentId,
        studentIdentifier,
        scanTimestamp,
        studentAnswers,
        correctAnswers,
        scores,
        finalGrade,
        imagePath,
        isSynced,
        assessmentName,
        pointValues,
      ];
}