import 'package:hive_flutter/hive_flutter.dart';
import '../models/corrected_exam.dart';

class CorrectionRepository {
  static const String _correctedExamsBoxName = 'corrected_exams';
  static const String _batchSummaryBoxName = 'batch_summary';
  
  late Box<CorrectedExam> _correctedExamsBox;
  late Box _batchSummaryBox;

  Future<void> initialize() async {
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CorrectedExamAdapter());
    }

    // Open boxes
    _correctedExamsBox = await Hive.openBox<CorrectedExam>(_correctedExamsBoxName);
    _batchSummaryBox = await Hive.openBox(_batchSummaryBoxName);
  }

  Future<void> saveCorrectedExam(CorrectedExam exam) async {
    await _correctedExamsBox.put(exam.examId, exam);
  }

  Future<void> saveCorrectedExams(List<CorrectedExam> exams) async {
    final Map<String, CorrectedExam> examMap = {
      for (var exam in exams) exam.examId: exam
    };
    await _correctedExamsBox.putAll(examMap);
  }

  CorrectedExam? getCorrectedExam(String examId) {
    return _correctedExamsBox.get(examId);
  }

  List<CorrectedExam> getAllCorrectedExams() {
    return _correctedExamsBox.values.toList();
  }

  List<CorrectedExam> getCorrectedExamsByAssessment(String assessmentId) {
    return _correctedExamsBox.values
        .where((exam) => exam.assessmentId == assessmentId)
        .toList();
  }

  List<CorrectedExam> getUnsyncedExams() {
    return _correctedExamsBox.values
        .where((exam) => !exam.isSynced)
        .toList();
  }

  Future<void> markAsSynced(String examId) async {
    final exam = _correctedExamsBox.get(examId);
    if (exam != null) {
      final updatedExam = exam.copyWith(isSynced: true);
      await _correctedExamsBox.put(examId, updatedExam);
    }
  }

  Future<void> markAllAsSynced(List<String> examIds) async {
    for (final examId in examIds) {
      await markAsSynced(examId);
    }
  }

  Future<void> deleteCorrectedExam(String examId) async {
    await _correctedExamsBox.delete(examId);
  }

  Future<void> deleteAllCorrectedExams() async {
    await _correctedExamsBox.clear();
  }

  // Batch session management
  Future<void> startBatchSession() async {
    await _batchSummaryBox.put('current_batch_start', DateTime.now().toIso8601String());
    await _batchSummaryBox.put('current_batch_exams', <String>[]);
  }

  Future<void> addToBatch(String examId) async {
    final currentBatch = getCurrentBatchExams();
    currentBatch.add(examId);
    await _batchSummaryBox.put('current_batch_exams', currentBatch);
  }

  Future<void> endBatchSession() async {
    final startTime = _batchSummaryBox.get('current_batch_start') as String?;
    final examIds = getCurrentBatchExams();
    
    if (startTime != null && examIds.isNotEmpty) {
      final batchId = DateTime.now().millisecondsSinceEpoch.toString();
      await _batchSummaryBox.put('batch_$batchId', {
        'start_time': startTime,
        'end_time': DateTime.now().toIso8601String(),
        'exam_ids': examIds,
        'exam_count': examIds.length,
      });
    }
    
    // Clear current batch
    await _batchSummaryBox.delete('current_batch_start');
    await _batchSummaryBox.delete('current_batch_exams');
  }

  List<String> getCurrentBatchExams() {
    final examIds = _batchSummaryBox.get('current_batch_exams');
    if (examIds is List) {
      return List<String>.from(examIds);
    }
    return <String>[];
  }

  bool get isInBatchMode {
    return _batchSummaryBox.containsKey('current_batch_start');
  }

  List<Map<String, dynamic>> getBatchHistory() {
    final batches = <Map<String, dynamic>>[];
    for (final key in _batchSummaryBox.keys) {
      if (key.toString().startsWith('batch_')) {
        final batch = _batchSummaryBox.get(key) as Map?;
        if (batch != null) {
          batches.add(Map<String, dynamic>.from(batch));
        }
      }
    }
    return batches;
  }

  // Statistics
  int get totalExamsCount => _correctedExamsBox.length;
  
  int get unsyncedExamsCount => getUnsyncedExams().length;
  
  double getAverageScore({String? assessmentId}) {
    final exams = assessmentId != null 
        ? getCorrectedExamsByAssessment(assessmentId)
        : getAllCorrectedExams();
    
    if (exams.isEmpty) return 0.0;
    
    final totalScore = exams.fold<double>(0, (sum, exam) => sum + exam.finalGrade);
    return totalScore / exams.length;
  }

  Map<String, int> getGradeDistribution({String? assessmentId}) {
    final exams = assessmentId != null 
        ? getCorrectedExamsByAssessment(assessmentId)
        : getAllCorrectedExams();
    
    final distribution = <String, int>{
      '0-20': 0,
      '21-40': 0,
      '41-60': 0,
      '61-80': 0,
      '81-100': 0,
    };

    for (final exam in exams) {
      final percentage = exam.percentageScore;
      if (percentage <= 20) {
        distribution['0-20'] = distribution['0-20']! + 1;
      } else if (percentage <= 40) {
        distribution['21-40'] = distribution['21-40']! + 1;
      } else if (percentage <= 60) {
        distribution['41-60'] = distribution['41-60']! + 1;
      } else if (percentage <= 80) {
        distribution['61-80'] = distribution['61-80']! + 1;
      } else {
        distribution['81-100'] = distribution['81-100']! + 1;
      }
    }

    return distribution;
  }

  Future<void> close() async {
    await _correctedExamsBox.close();
    await _batchSummaryBox.close();
  }
}