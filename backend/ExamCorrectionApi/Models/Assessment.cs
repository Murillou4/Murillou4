using System.ComponentModel.DataAnnotations;

namespace ExamCorrectionApi.Models;

public class Assessment
{
    public Guid Id { get; set; } = Guid.NewGuid();
    
    [Required]
    [StringLength(200)]
    public string Name { get; set; } = string.Empty;
    
    [Required]
    public Guid TeacherId { get; set; }
    
    [Required]
    [Range(1, 200)]
    public int QuestionCount { get; set; }
    
    [Required]
    public List<string> AnswerKey { get; set; } = new();
    
    [Required]
    public Dictionary<string, int> PointValues { get; set; } = new();
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    
    public DateTime? ExpiresAt { get; set; }
    
    [StringLength(500)]
    public string? Description { get; set; }
}