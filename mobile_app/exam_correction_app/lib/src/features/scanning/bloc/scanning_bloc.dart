import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../../../core/services/jwt_service.dart';
import '../../../core/services/omr_service.dart';
import '../../../core/repositories/correction_repository.dart';
import '../../../core/models/qr_payload.dart';
import '../../../core/models/corrected_exam.dart';
import 'scanning_event.dart';
import 'scanning_state.dart';

class ScanningBloc extends Bloc<ScanningEvent, ScanningState> {
  final OmrService _omrService;
  final CorrectionRepository _repository;
  
  bool _isBatchMode = false;
  QrPayload? _currentQrPayload;
  final List<CorrectedExam> _batchResults = [];

  ScanningBloc({
    required OmrService omrService,
    required CorrectionRepository repository,
  })  : _omrService = omrService,
        _repository = repository,
        super(const ScanningInitial()) {
    
    on<ScanningStarted>(_onScanningStarted);
    on<QrCodeDetected>(_onQrCodeDetected);
    on<ImageCaptured>(_onImageCaptured);
    on<ProcessingStarted>(_onProcessingStarted);
    on<RetryScanning>(_onRetryScanning);
    on<ClearState>(_onClearState);
    on<BatchModeToggled>(_onBatchModeToggled);
    on<AddToBatch>(_onAddToBatch);
    on<FinalizeBatch>(_onFinalizeBatch);
  }

  void _onScanningStarted(ScanningStarted event, Emitter<ScanningState> emit) {
    emit(ScanningReady(
      isBatchMode: _isBatchMode,
      batchCount: _batchResults.length,
    ));
  }

  void _onQrCodeDetected(QrCodeDetected event, Emitter<ScanningState> emit) async {
    try {
      final qrData = event.capture.barcodes.first.rawValue;
      if (qrData == null || qrData.isEmpty) {
        emit(QrCodeValidationError(
          message: 'QR code vazio ou inválido',
          isBatchMode: _isBatchMode,
          batchCount: _batchResults.length,
        ));
        return;
      }

      // Validate JWT token
      if (!JwtService.validateToken(qrData)) {
        emit(QrCodeValidationError(
          message: 'QR code inválido ou adulterado',
          isBatchMode: _isBatchMode,
          batchCount: _batchResults.length,
        ));
        return;
      }

      // Decode payload
      final payload = JwtService.decodePayload(qrData);
      if (payload == null) {
        emit(QrCodeValidationError(
          message: 'Erro ao decodificar dados do QR code',
          isBatchMode: _isBatchMode,
          batchCount: _batchResults.length,
        ));
        return;
      }

      // Check if expired
      if (payload.isExpired) {
        emit(QrCodeValidationError(
          message: 'QR code expirado',
          isBatchMode: _isBatchMode,
          batchCount: _batchResults.length,
        ));
        return;
      }

      _currentQrPayload = payload;
      emit(QrCodeDetectedState(
        qrPayload: payload,
        isBatchMode: _isBatchMode,
        batchCount: _batchResults.length,
      ));
    } catch (e) {
      emit(ScanningError(
        message: 'Erro ao processar QR code: ${e.toString()}',
        isBatchMode: _isBatchMode,
        batchCount: _batchResults.length,
      ));
    }
  }

  void _onImageCaptured(ImageCaptured event, Emitter<ScanningState> emit) async {
    if (_currentQrPayload == null) {
      emit(ScanningError(
        message: 'QR code deve ser escaneado primeiro',
        isBatchMode: _isBatchMode,
        batchCount: _batchResults.length,
      ));
      return;
    }

    emit(ProcessingImage(
      qrPayload: _currentQrPayload!,
      imagePath: event.imagePath,
      isBatchMode: _isBatchMode,
      batchCount: _batchResults.length,
    ));

    try {
      // Process the image with OMR
      final processingResult = await _omrService.processImageWithQualityCheck(
        event.imagePath,
        _currentQrPayload!.questionCount,
      );

      if (!processingResult.success) {
        emit(ScanningError(
          message: processingResult.error ?? 'Erro no processamento da imagem',
          isBatchMode: _isBatchMode,
          batchCount: _batchResults.length,
        ));
        return;
      }

      // Calculate scores
      final correctedExam = _omrService.calculateScore(
        studentAnswers: processingResult.detectedAnswers,
        qrPayload: _currentQrPayload!,
        imagePath: event.imagePath,
      );

      // Save to local database
      await _repository.saveCorrectedExam(correctedExam);

      if (_isBatchMode) {
        // Add to batch and continue scanning
        _batchResults.add(correctedExam);
        await _repository.addToBatch(correctedExam.examId);
        
        emit(ScanningReady(
          isBatchMode: _isBatchMode,
          batchCount: _batchResults.length,
        ));
      } else {
        // Single exam completed
        emit(ProcessingCompleted(
          correctedExam: correctedExam,
          isBatchMode: _isBatchMode,
          batchCount: _batchResults.length,
        ));
      }

      // Reset current QR payload for next scan
      _currentQrPayload = null;
    } catch (e) {
      emit(ScanningError(
        message: 'Erro durante o processamento: ${e.toString()}',
        isBatchMode: _isBatchMode,
        batchCount: _batchResults.length,
      ));
    }
  }

  void _onProcessingStarted(ProcessingStarted event, Emitter<ScanningState> emit) {
    // This is handled by ImageCaptured event
  }

  void _onRetryScanning(RetryScanning event, Emitter<ScanningState> emit) {
    _currentQrPayload = null;
    emit(ScanningReady(
      isBatchMode: _isBatchMode,
      batchCount: _batchResults.length,
    ));
  }

  void _onClearState(ClearState event, Emitter<ScanningState> emit) {
    _currentQrPayload = null;
    emit(const ScanningInitial());
  }

  void _onBatchModeToggled(BatchModeToggled event, Emitter<ScanningState> emit) async {
    _isBatchMode = event.enabled;
    
    if (_isBatchMode) {
      // Start new batch session
      await _repository.startBatchSession();
      _batchResults.clear();
    } else if (_batchResults.isNotEmpty) {
      // End current batch session
      await _repository.endBatchSession();
      
      // Calculate batch statistics
      final batchStats = _calculateBatchStats(_batchResults);
      
      emit(BatchCompleted(
        batchResults: List.from(_batchResults),
        batchStats: batchStats,
      ));
      
      _batchResults.clear();
      return;
    }

    emit(ScanningReady(
      isBatchMode: _isBatchMode,
      batchCount: _batchResults.length,
    ));
  }

  void _onAddToBatch(AddToBatch event, Emitter<ScanningState> emit) async {
    await _repository.addToBatch(event.examId);
  }

  void _onFinalizeBatch(FinalizeBatch event, Emitter<ScanningState> emit) async {
    if (_batchResults.isEmpty) {
      emit(ScanningError(
        message: 'Nenhuma prova foi processada no lote',
        isBatchMode: _isBatchMode,
        batchCount: _batchResults.length,
      ));
      return;
    }

    await _repository.endBatchSession();
    
    final batchStats = _calculateBatchStats(_batchResults);
    
    emit(BatchCompleted(
      batchResults: List.from(_batchResults),
      batchStats: batchStats,
    ));

    _isBatchMode = false;
    _batchResults.clear();
  }

  Map<String, dynamic> _calculateBatchStats(List<CorrectedExam> exams) {
    if (exams.isEmpty) {
      return {
        'total_exams': 0,
        'average_score': 0.0,
        'highest_score': 0.0,
        'lowest_score': 0.0,
        'completion_time': '0 min',
      };
    }

    final scores = exams.map((e) => e.finalGrade).toList();
    final averageScore = scores.reduce((a, b) => a + b) / scores.length;
    final highestScore = scores.reduce((a, b) => a > b ? a : b);
    final lowestScore = scores.reduce((a, b) => a < b ? a : b);
    
    final startTime = exams.first.scanTimestamp;
    final endTime = exams.last.scanTimestamp;
    final duration = endTime.difference(startTime).inMinutes;

    return {
      'total_exams': exams.length,
      'average_score': averageScore,
      'highest_score': highestScore,
      'lowest_score': lowestScore,
      'completion_time': '$duration min',
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
    };
  }

  /// Save captured image to app documents directory
  Future<String> saveImageToStorage(List<int> imageBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(path.join(directory.path, 'exam_images'));
    
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    final filePath = path.join(imagesDir.path, fileName);
    final file = File(filePath);
    await file.writeAsBytes(imageBytes);
    
    return filePath;
  }
}