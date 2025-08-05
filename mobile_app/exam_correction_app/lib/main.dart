import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'src/core/repositories/correction_repository.dart';
import 'src/core/services/omr_service.dart';
import 'src/features/scanning/bloc/scanning_bloc.dart';
import 'src/features/scanning/view/scanning_screen.dart';
import 'src/features/results/view/results_screen.dart';
import 'src/features/batch/view/batch_results_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local database
  final repository = CorrectionRepository();
  await repository.initialize();
  
  runApp(ExamCorrectionApp(repository: repository));
}

class ExamCorrectionApp extends StatelessWidget {
  final CorrectionRepository repository;

  const ExamCorrectionApp({
    super.key,
    required this.repository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: repository),
        RepositoryProvider(create: (_) => OmrService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => ScanningBloc(
              omrService: context.read<OmrService>(),
              repository: context.read<CorrectionRepository>(),
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'Correção Automática de Provas',
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
            ),
          ),
          routerConfig: _router,
        ),
      ),
    );
  }

  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/scan',
        name: 'scan',
        builder: (context, state) => const ScanningScreen(),
      ),
      GoRoute(
        path: '/results/:examId',
        name: 'results',
        builder: (context, state) {
          final examId = state.pathParameters['examId']!;
          return ResultsScreen(examId: examId);
        },
      ),
      GoRoute(
        path: '/batch-results',
        name: 'batch-results',
        builder: (context, state) {
          final results = state.extra as List<dynamic>?;
          return BatchResultsScreen(
            batchResults: results?[0] as List? ?? [],
            batchStats: results?[1] as Map<String, dynamic>? ?? {},
          );
        },
      ),
    ],
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correção Automática'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            const Icon(
              Icons.document_scanner,
              size: 120,
              color: Colors.blue,
            ),
            const SizedBox(height: 32),
            const Text(
              'Plataforma de Correção Automática de Provas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Escaneie QR codes para identificar provas e processe automaticamente as respostas usando tecnologia OMR.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () => context.go('/scan'),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Iniciar Escaneamento'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showExamHistory(context),
              icon: const Icon(Icons.history),
              label: const Text('Histórico de Provas'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => _showStatistics(context),
              icon: const Icon(Icons.analytics),
              label: const Text('Estatísticas'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const Spacer(),
            _buildInfoCards(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                context,
                'Offline First',
                'Funciona sem internet',
                Icons.wifi_off,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                context,
                'Seguro',
                'QR codes assinados',
                Icons.security,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                context,
                'Preciso',
                'OMR com OpenCV',
                Icons.precision_manufacturing,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoCard(
                context,
                'Relatórios',
                'Export para Excel',
                Icons.table_chart,
                Colors.blue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showExamHistory(BuildContext context) {
    final repository = context.read<CorrectionRepository>();
    final exams = repository.getAllCorrectedExams();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Histórico de Provas'),
        content: SizedBox(
          width: double.maxFinite,
          child: exams.isEmpty
              ? const Text('Nenhuma prova corrigida ainda.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: exams.length,
                  itemBuilder: (context, index) {
                    final exam = exams[index];
                    return ListTile(
                      title: Text(exam.assessmentName),
                      subtitle: Text('Nota: ${exam.finalGrade.toStringAsFixed(1)}'),
                      trailing: Text(
                        '${exam.scanTimestamp.day}/${exam.scanTimestamp.month}',
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        context.go('/results/${exam.examId}');
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showStatistics(BuildContext context) {
    final repository = context.read<CorrectionRepository>();
    final totalExams = repository.totalExamsCount;
    final averageScore = repository.getAverageScore();
    final distribution = repository.getGradeDistribution();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Estatísticas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total de provas: $totalExams'),
            Text('Nota média: ${averageScore.toStringAsFixed(1)}'),
            const SizedBox(height: 16),
            const Text('Distribuição de notas:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...distribution.entries.map((entry) => 
              Text('${entry.key}%: ${entry.value} provas')
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}
