import 'package:equatable/equatable.dart';
import '../../../core/models/qr_payload.dart';
import '../../../core/models/corrected_exam.dart';

abstract class ScanningState extends Equatable {
  const ScanningState();

  @override
  List<Object?> get props => [];
}

class ScanningInitial extends ScanningState {
  const ScanningInitial();
}

class ScanningReady extends ScanningState {
  final bool isBatchMode;
  final int batchCount;

  const ScanningReady({
    this.isBatchMode = false,
    this.batchCount = 0,
  });

  @override
  List<Object?> get props => [isBatchMode, batchCount];
}

class QrCodeDetectedState extends ScanningState {
  final QrPayload qrPayload;
  final bool isBatchMode;
  final int batchCount;

  const QrCodeDetectedState({
    required this.qrPayload,
    this.isBatchMode = false,
    this.batchCount = 0,
  });

  @override
  List<Object?> get props => [qrPayload, isBatchMode, batchCount];
}

class ProcessingImage extends ScanningState {
  final QrPayload qrPayload;
  final String imagePath;
  final bool isBatchMode;
  final int batchCount;

  const ProcessingImage({
    required this.qrPayload,
    required this.imagePath,
    this.isBatchMode = false,
    this.batchCount = 0,
  });

  @override
  List<Object?> get props => [qrPayload, imagePath, isBatchMode, batchCount];
}

class ProcessingCompleted extends ScanningState {
  final CorrectedExam correctedExam;
  final bool isBatchMode;
  final int batchCount;

  const ProcessingCompleted({
    required this.correctedExam,
    this.isBatchMode = false,
    this.batchCount = 0,
  });

  @override
  List<Object?> get props => [correctedExam, isBatchMode, batchCount];
}

class BatchCompleted extends ScanningState {
  final List<CorrectedExam> batchResults;
  final Map<String, dynamic> batchStats;

  const BatchCompleted({
    required this.batchResults,
    required this.batchStats,
  });

  @override
  List<Object?> get props => [batchResults, batchStats];
}

class ScanningError extends ScanningState {
  final String message;
  final bool isBatchMode;
  final int batchCount;
  final bool canRetry;

  const ScanningError({
    required this.message,
    this.isBatchMode = false,
    this.batchCount = 0,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, isBatchMode, batchCount, canRetry];
}

class QrCodeValidationError extends ScanningState {
  final String message;
  final bool isBatchMode;
  final int batchCount;

  const QrCodeValidationError({
    required this.message,
    this.isBatchMode = false,
    this.batchCount = 0,
  });

  @override
  List<Object?> get props => [message, isBatchMode, batchCount];
}