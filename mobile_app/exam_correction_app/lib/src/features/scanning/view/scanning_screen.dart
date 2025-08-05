import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';

import '../bloc/scanning_bloc.dart';
import '../bloc/scanning_event.dart';
import '../bloc/scanning_state.dart';

class ScanningScreen extends StatefulWidget {
  const ScanningScreen({super.key});

  @override
  State<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends State<ScanningScreen> {
  MobileScannerController? _controller;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
    context.read<ScanningBloc>().add(const ScanningStarted());
  }

  void _initializeScanner() {
    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escaneamento'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          BlocBuilder<ScanningBloc, ScanningState>(
            builder: (context, state) {
              final isBatchMode = state is ScanningReady ? state.isBatchMode : false;
              return PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'batch') {
                    context.read<ScanningBloc>().add(BatchModeToggled(!isBatchMode));
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'batch',
                    child: Row(
                      children: [
                        Icon(isBatchMode ? Icons.check_box : Icons.check_box_outline_blank),
                        const SizedBox(width: 8),
                        const Text('Modo Lote'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: BlocListener<ScanningBloc, ScanningState>(
        listener: (context, state) {
          if (state is ProcessingCompleted && !state.isBatchMode) {
            // Navigate to results for single exam
            context.pushReplacement('/results/${state.correctedExam.examId}');
          } else if (state is BatchCompleted) {
            // Navigate to batch results
            context.pushReplacement('/batch-results', extra: [
              state.batchResults,
              state.batchStats,
            ]);
          } else if (state is ScanningError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                action: state.canRetry
                    ? SnackBarAction(
                        label: 'Tentar Novamente',
                        onPressed: () {
                          context.read<ScanningBloc>().add(const RetryScanning());
                        },
                      )
                    : null,
              ),
            );
          } else if (state is QrCodeValidationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        child: BlocBuilder<ScanningBloc, ScanningState>(
          builder: (context, state) {
            return Stack(
              children: [
                // Camera View
                if (_controller != null)
                  MobileScanner(
                    controller: _controller!,
                    onDetect: _isScanning
                        ? (capture) {
                            _isScanning = false;
                            context.read<ScanningBloc>().add(QrCodeDetected(capture));
                            
                            // Re-enable scanning after a delay
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) {
                                setState(() {
                                  _isScanning = true;
                                });
                              }
                            });
                          }
                        : null,
                  ),
                
                // Overlay
                _buildOverlay(state),
                
                // Status Information
                _buildStatusBar(state),
              ],
            );
          },
        ),
      ),
      floatingActionButton: BlocBuilder<ScanningBloc, ScanningState>(
        builder: (context, state) {
          if (state is QrCodeDetectedState) {
            return FloatingActionButton.extended(
              onPressed: () => _captureImage(context),
              icon: const Icon(Icons.camera),
              label: const Text('Capturar Imagem'),
            );
          } else if (state is ScanningReady && state.isBatchMode && state.batchCount > 0) {
            return FloatingActionButton.extended(
              onPressed: () {
                context.read<ScanningBloc>().add(const FinalizeBatch());
              },
              icon: const Icon(Icons.done_all),
              label: Text('Finalizar Lote (${state.batchCount})'),
              backgroundColor: Colors.green,
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildOverlay(ScanningState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ),
      child: CustomPaint(
        painter: ScannerOverlayPainter(),
        child: Container(),
      ),
    );
  }

  Widget _buildStatusBar(ScanningState state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusText(state),
            if (state is ScanningReady && state.isBatchMode)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'MODO LOTE: ${state.batchCount} provas',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusText(ScanningState state) {
    String text;
    Color color;
    IconData icon;

    if (state is ScanningReady) {
      text = 'Posicione o QR code na área de escaneamento';
      color = Colors.white;
      icon = Icons.qr_code_scanner;
    } else if (state is QrCodeDetectedState) {
      text = 'QR code detectado: ${state.qrPayload.assessmentName}';
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (state is ProcessingImage) {
      text = 'Processando imagem...';
      color = Colors.blue;
      icon = Icons.hourglass_empty;
    } else if (state is ProcessingCompleted) {
      text = 'Prova corrigida! Nota: ${state.correctedExam.finalGrade.toStringAsFixed(1)}';
      color = Colors.green;
      icon = Icons.done;
    } else if (state is ScanningError) {
      text = 'Erro: ${state.message}';
      color = Colors.red;
      icon = Icons.error;
    } else if (state is QrCodeValidationError) {
      text = 'QR Code inválido: ${state.message}';
      color = Colors.orange;
      icon = Icons.warning;
    } else {
      text = 'Inicializando...';
      color = Colors.white;
      icon = Icons.hourglass_empty;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _captureImage(BuildContext context) {
    // For demo purposes, we'll simulate image capture
    // In a real implementation, this would use the camera to take a high-resolution photo
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final imagePath = '/simulated/path/exam_$timestamp.jpg';
    
    context.read<ScanningBloc>().add(ImageCaptured(imagePath));
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double scanAreaSize = 250.0;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final rect = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);
    
    // Draw corner brackets
    const double cornerLength = 30.0;
    
    // Top-left corner
    canvas.drawLine(
      Offset(left, top + cornerLength),
      Offset(left, top),
      paint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      paint,
    );
    
    // Top-right corner
    canvas.drawLine(
      Offset(left + scanAreaSize - cornerLength, top),
      Offset(left + scanAreaSize, top),
      paint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize, top + cornerLength),
      paint,
    );
    
    // Bottom-left corner
    canvas.drawLine(
      Offset(left, top + scanAreaSize - cornerLength),
      Offset(left, top + scanAreaSize),
      paint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left + cornerLength, top + scanAreaSize),
      paint,
    );
    
    // Bottom-right corner
    canvas.drawLine(
      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
      Offset(left + scanAreaSize, top + scanAreaSize),
      paint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),
      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}