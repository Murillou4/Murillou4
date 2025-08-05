import 'package:flutter/material.dart';
import '../../../core/models/corrected_exam.dart';

class BatchResultsScreen extends StatelessWidget {
  final List<CorrectedExam> batchResults;
  final Map<String, dynamic> batchStats;

  const BatchResultsScreen({
    super.key,
    required this.batchResults,
    required this.batchStats,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados do Lote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: () => _exportToExcel(context),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareResults(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatsSummary(),
            const SizedBox(height: 24),
            _buildResultsList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estatísticas do Lote',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total de Provas',
                    '${batchStats['total_exams'] ?? 0}',
                    Icons.assignment,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Nota Média',
                    '${(batchStats['average_score'] ?? 0.0).toStringAsFixed(1)}',
                    Icons.bar_chart,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Maior Nota',
                    '${(batchStats['highest_score'] ?? 0.0).toStringAsFixed(1)}',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Menor Nota',
                    '${(batchStats['lowest_score'] ?? 0.0).toStringAsFixed(1)}',
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text('Tempo de processamento: ${batchStats['completion_time'] ?? 'N/A'}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resultados Individuais',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (batchResults.isEmpty)
              const Center(
                child: Text('Nenhum resultado encontrado'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: batchResults.length,
                itemBuilder: (context, index) {
                  final exam = batchResults[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getScoreColor(exam.percentageScore),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        exam.studentIdentifier ?? 'Prova ${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(exam.assessmentName),
                          Text('${exam.correctCount}/${exam.totalQuestions} corretas'),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${exam.finalGrade.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${exam.percentageScore.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: _getScoreColor(exam.percentageScore),
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _showExamDetails(context, exam),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double percentage) {
    if (percentage >= 70) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  void _showExamDetails(BuildContext context, CorrectedExam exam) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exam.studentIdentifier ?? 'Detalhes da Prova'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Avaliação: ${exam.assessmentName}'),
              Text('Nota: ${exam.finalGrade.toStringAsFixed(1)}'),
              Text('Acertos: ${exam.correctCount}/${exam.totalQuestions}'),
              Text('Percentual: ${exam.percentageScore.toStringAsFixed(1)}%'),
              Text('Data: ${_formatDate(exam.scanTimestamp)}'),
              const SizedBox(height: 16),
              const Text(
                'Resumo por questão:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...List.generate(exam.totalQuestions, (index) {
                final studentAnswer = index < exam.studentAnswers.length 
                    ? exam.studentAnswers[index] 
                    : 'NONE';
                final correctAnswer = index < exam.correctAnswers.length 
                    ? exam.correctAnswers[index] 
                    : '';
                final isCorrect = index < exam.scores.length && exam.scores[index] > 0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text('${index + 1}:'),
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          studentAnswer,
                          style: TextStyle(
                            color: isCorrect ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text('(${correctAnswer})'),
                      if (isCorrect) 
                        const Icon(Icons.check, color: Colors.green, size: 16)
                      else
                        const Icon(Icons.close, color: Colors.red, size: 16),
                    ],
                  ),
                );
              }),
            ],
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _exportToExcel(BuildContext context) {
    // Placeholder for Excel export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportação para Excel será implementada'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _shareResults(BuildContext context) {
    // Placeholder for sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de compartilhamento será implementada'),
      ),
    );
  }
}