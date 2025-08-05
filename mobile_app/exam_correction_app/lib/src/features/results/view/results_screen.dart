import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/repositories/correction_repository.dart';
import '../../../core/models/corrected_exam.dart';

class ResultsScreen extends StatelessWidget {
  final String examId;

  const ResultsScreen({
    super.key,
    required this.examId,
  });

  @override
  Widget build(BuildContext context) {
    final repository = context.read<CorrectionRepository>();
    final exam = repository.getCorrectedExam(examId);

    if (exam == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Resultado'),
        ),
        body: const Center(
          child: Text('Prova não encontrada'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultado da Prova'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareResults(context, exam),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(exam),
            const SizedBox(height: 24),
            _buildScoreSummary(exam),
            const SizedBox(height: 24),
            _buildQuestionDetails(exam),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CorrectedExam exam) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exam.assessmentName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (exam.studentIdentifier != null)
              Text('Aluno: ${exam.studentIdentifier}'),
            Text('Data: ${_formatDate(exam.scanTimestamp)}'),
            Text('ID: ${exam.examId.substring(0, 8)}...'),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreSummary(CorrectedExam exam) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Nota Final',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    exam.finalGrade.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 1,
              height: 60,
              color: Colors.grey[300],
            ),
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Acertos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${exam.correctCount}/${exam.totalQuestions}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text('${exam.percentageScore.toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionDetails(CorrectedExam exam) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalhes por Questão',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: exam.totalQuestions,
              itemBuilder: (context, index) {
                final studentAnswer = index < exam.studentAnswers.length 
                    ? exam.studentAnswers[index] 
                    : 'NONE';
                final correctAnswer = index < exam.correctAnswers.length 
                    ? exam.correctAnswers[index] 
                    : '';
                final score = index < exam.scores.length 
                    ? exam.scores[index] 
                    : 0;
                final isCorrect = score > 0;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getQuestionColor(studentAnswer, isCorrect),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text('Resposta: '),
                      Text(
                        studentAnswer,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getAnswerColor(studentAnswer, isCorrect),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text('Gabarito: $correctAnswer'),
                  trailing: Text(
                    '$score pts',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getQuestionColor(String studentAnswer, bool isCorrect) {
    if (studentAnswer == 'ERROR') return Colors.orange;
    if (studentAnswer == 'NONE') return Colors.grey;
    return isCorrect ? Colors.green : Colors.red;
  }

  Color _getAnswerColor(String studentAnswer, bool isCorrect) {
    if (studentAnswer == 'ERROR') return Colors.orange;
    if (studentAnswer == 'NONE') return Colors.grey;
    return isCorrect ? Colors.green : Colors.red;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _shareResults(BuildContext context, CorrectedExam exam) {
    // Placeholder for sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de compartilhamento será implementada'),
      ),
    );
  }
}