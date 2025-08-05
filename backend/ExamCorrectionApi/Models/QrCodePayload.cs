namespace ExamCorrectionApi.Models;

public class QrCodePayload
{
    public string AssessmentId { get; set; } = string.Empty;
    public string TeacherId { get; set; } = string.Empty;
    public string IssuedAt { get; set; } = string.Empty;
    public string? ExpiresAt { get; set; }
    public List<string> AnswerKey { get; set; } = new();
    public Dictionary<string, int> PointValues { get; set; } = new();
    public int QuestionCount { get; set; }
    public string AssessmentName { get; set; } = string.Empty;
}