using ExamCorrectionApi.Models;
using System.Collections.Concurrent;

namespace ExamCorrectionApi.Services;

public class AssessmentService
{
    private readonly ConcurrentDictionary<Guid, Assessment> _assessments = new();

    public Assessment CreateAssessment(string name, Guid teacherId, int questionCount, 
        List<string> answerKey, Dictionary<string, int> pointValues, string? description = null, 
        DateTime? expiresAt = null)
    {
        if (answerKey.Count != questionCount)
        {
            throw new ArgumentException("Answer key count must match question count");
        }

        var assessment = new Assessment
        {
            Name = name,
            TeacherId = teacherId,
            QuestionCount = questionCount,
            AnswerKey = answerKey,
            PointValues = pointValues,
            Description = description,
            ExpiresAt = expiresAt
        };

        _assessments.TryAdd(assessment.Id, assessment);
        return assessment;
    }

    public Assessment? GetAssessment(Guid id)
    {
        _assessments.TryGetValue(id, out var assessment);
        return assessment;
    }

    public List<Assessment> GetAssessmentsByTeacher(Guid teacherId)
    {
        return _assessments.Values
            .Where(a => a.TeacherId == teacherId)
            .OrderByDescending(a => a.CreatedAt)
            .ToList();
    }

    public List<Assessment> GetAllAssessments()
    {
        return _assessments.Values
            .OrderByDescending(a => a.CreatedAt)
            .ToList();
    }

    public bool UpdateAssessment(Guid id, Assessment updatedAssessment)
    {
        if (!_assessments.ContainsKey(id))
        {
            return false;
        }

        updatedAssessment.Id = id;
        _assessments.TryUpdate(id, updatedAssessment, _assessments[id]);
        return true;
    }

    public bool DeleteAssessment(Guid id)
    {
        return _assessments.TryRemove(id, out _);
    }

    public Assessment CreateSampleAssessment(Guid teacherId)
    {
        var answerKey = new List<string> { "A", "B", "C", "D", "A", "C", "B", "D", "A", "C" };
        var pointValues = new Dictionary<string, int>
        {
            { "A", 1 },
            { "B", 1 },
            { "C", 1 },
            { "D", 1 }
        };

        return CreateAssessment(
            "História - Turma 10A - Prova Bimestral",
            teacherId,
            10,
            answerKey,
            pointValues,
            "Prova bimestral de História sobre o período colonial brasileiro",
            DateTime.UtcNow.AddDays(30)
        );
    }
}