import 'package:equatable/equatable.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

abstract class ScanningEvent extends Equatable {
  const ScanningEvent();

  @override
  List<Object?> get props => [];
}

class ScanningStarted extends ScanningEvent {
  const ScanningStarted();
}

class QrCodeDetected extends ScanningEvent {
  final BarcodeCapture capture;

  const QrCodeDetected(this.capture);

  @override
  List<Object?> get props => [capture];
}

class ImageCaptured extends ScanningEvent {
  final String imagePath;

  const ImageCaptured(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}

class ProcessingStarted extends ScanningEvent {
  const ProcessingStarted();
}

class RetryScanning extends ScanningEvent {
  const RetryScanning();
}

class ClearState extends ScanningEvent {
  const ClearState();
}

class BatchModeToggled extends ScanningEvent {
  final bool enabled;

  const BatchModeToggled(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class AddToBatch extends ScanningEvent {
  final String examId;

  const AddToBatch(this.examId);

  @override
  List<Object?> get props => [examId];
}

class FinalizeBatch extends ScanningEvent {
  const FinalizeBatch();
}