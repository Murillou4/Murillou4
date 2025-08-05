import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/qr_payload.dart';
import '../models/corrected_exam.dart';
import 'package:uuid/uuid.dart';

class OmrProcessingResult {
  final List<String> detectedAnswers;
  final bool success;
  final String? error;
  final List<double> confidenceScores;

  const OmrProcessingResult({
    required this.detectedAnswers,
    required this.success,
    this.error,
    this.confidenceScores = const [],
  });
}

class OmrService {
  static const double _markThreshold = 0.3; // 30% filled to be considered marked
  static const List<String> _validOptions = ['A', 'B', 'C', 'D', 'E'];

  /// Process an image and extract OMR marks
  /// This is a simplified implementation for demonstration
  /// In production, this would interface with OpenCV via FFI
  Future<OmrProcessingResult> processImage(String imagePath, int questionCount) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return const OmrProcessingResult(
          detectedAnswers: [],
          success: false,
          error: 'Image file not found',
        );
      }

      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        return const OmrProcessingResult(
          detectedAnswers: [],
          success: false,
          error: 'Failed to decode image',
        );
      }

      // Simulate OMR processing
      // In a real implementation, this would:
      // 1. Convert to grayscale
      // 2. Apply perspective correction using fiducial markers
      // 3. Segment the answer grid
      // 4. Analyze each bubble for mark density
      // 5. Determine the selected answer for each question
      
      final detectedAnswers = _simulateOmrDetection(image, questionCount);
      
      return OmrProcessingResult(
        detectedAnswers: detectedAnswers,
        success: true,
        confidenceScores: List.filled(questionCount, 0.85), // Simulated confidence
      );
    } catch (e) {
      return OmrProcessingResult(
        detectedAnswers: [],
        success: false,
        error: 'Processing error: ${e.toString()}',
      );
    }
  }

  /// Simulate OMR detection for demonstration purposes
  List<String> _simulateOmrDetection(img.Image image, int questionCount) {
    // This is a simulation for demonstration
    // Real implementation would analyze actual bubble marks
    final answers = <String>[];
    final random = DateTime.now().millisecondsSinceEpoch;
    
    for (int i = 0; i < questionCount; i++) {
      // Simulate some variety in answers
      final answerIndex = (random + i) % _validOptions.length;
      
      // Occasionally simulate errors (multiple marks or no marks)
      if (i % 13 == 0) {
        answers.add('ERROR'); // Multiple marks detected
      } else if (i % 17 == 0) {
        answers.add('NONE'); // No mark detected
      } else {
        answers.add(_validOptions[answerIndex]);
      }
    }
    
    return answers;
  }

  /// Calculate the score for a corrected exam
  CorrectedExam calculateScore({
    required List<String> studentAnswers,
    required QrPayload qrPayload,
    required String imagePath,
    String? studentIdentifier,
  }) {
    final scores = <int>[];
    double totalScore = 0;

    for (int i = 0; i < qrPayload.questionCount; i++) {
      final studentAnswer = i < studentAnswers.length ? studentAnswers[i] : 'NONE';
      final correctAnswer = i < qrPayload.answerKey.length ? qrPayload.answerKey[i] : '';
      
      int questionScore = 0;
      
      if (studentAnswer == 'ERROR' || studentAnswer == 'NONE') {
        // No points for errors or unanswered questions
        questionScore = 0;
      } else if (studentAnswer == correctAnswer) {
        // Correct answer gets full points
        questionScore = qrPayload.pointValues[correctAnswer] ?? 1;
      } else {
        // Wrong answer gets zero points
        questionScore = 0;
      }
      
      scores.add(questionScore);
      totalScore += questionScore;
    }

    return CorrectedExam(
      examId: const Uuid().v4(),
      assessmentId: qrPayload.assessmentId,
      studentIdentifier: studentIdentifier,
      scanTimestamp: DateTime.now(),
      studentAnswers: studentAnswers,
      correctAnswers: qrPayload.answerKey,
      scores: scores,
      finalGrade: totalScore,
      imagePath: imagePath,
      assessmentName: qrPayload.assessmentName,
      pointValues: qrPayload.pointValues,
    );
  }

  /// Validate if the detected answers make sense
  bool validateAnswers(List<String> answers) {
    for (final answer in answers) {
      if (!_validOptions.contains(answer) && 
          answer != 'ERROR' && 
          answer != 'NONE') {
        return false;
      }
    }
    return true;
  }

  /// Get processing statistics
  Map<String, dynamic> getProcessingStats(List<String> answers) {
    int validAnswers = 0;
    int errors = 0;
    int unanswered = 0;
    
    for (final answer in answers) {
      if (_validOptions.contains(answer)) {
        validAnswers++;
      } else if (answer == 'ERROR') {
        errors++;
      } else if (answer == 'NONE') {
        unanswered++;
      }
    }
    
    return {
      'total_questions': answers.length,
      'valid_answers': validAnswers,
      'errors': errors,
      'unanswered': unanswered,
      'completion_rate': answers.isNotEmpty ? (validAnswers / answers.length) * 100 : 0,
    };
  }

  /// Enhanced processing with quality checks
  Future<OmrProcessingResult> processImageWithQualityCheck(
    String imagePath, 
    int questionCount,
    {double qualityThreshold = 0.7}
  ) async {
    final result = await processImage(imagePath, questionCount);
    
    if (!result.success) {
      return result;
    }

    // Check processing quality
    final stats = getProcessingStats(result.detectedAnswers);
    final completionRate = stats['completion_rate'] as double;
    
    if (completionRate < qualityThreshold * 100) {
      return OmrProcessingResult(
        detectedAnswers: result.detectedAnswers,
        success: false,
        error: 'Low quality scan detected. Completion rate: ${completionRate.toStringAsFixed(1)}%',
        confidenceScores: result.confidenceScores,
      );
    }

    return result;
  }
}