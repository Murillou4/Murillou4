using ExamCorrectionApi.Models;
using ExamCorrectionApi.Services;
using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container
builder.Services.AddSingleton<SecurityService>();
builder.Services.AddSingleton<AssessmentService>();
builder.Services.AddSingleton<QrCodeService>();
builder.Services.AddSingleton<AnswerSheetService>();

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
app.UseCors();

// Health check endpoint
app.MapGet("/", () => "Exam Correction API - Status: Running");

app.MapGet("/health", () => Results.Ok(new { 
    status = "healthy", 
    timestamp = DateTime.UtcNow,
    version = "1.0.0"
}));

// Get public key for mobile app
app.MapGet("/api/security/public-key", (SecurityService securityService) =>
{
    return Results.Ok(new { publicKey = securityService.GetPublicKeyPem() });
});

// Assessment Management Endpoints
app.MapPost("/api/assessments", (
    [FromBody] CreateAssessmentRequest request,
    AssessmentService assessmentService) =>
{
    try
    {
        var assessment = assessmentService.CreateAssessment(
            request.Name,
            request.TeacherId,
            request.QuestionCount,
            request.AnswerKey,
            request.PointValues,
            request.Description,
            request.ExpiresAt
        );

        return Results.Created($"/api/assessments/{assessment.Id}", assessment);
    }
    catch (ArgumentException ex)
    {
        return Results.BadRequest(new { error = ex.Message });
    }
});

app.MapGet("/api/assessments", (AssessmentService assessmentService) =>
{
    var assessments = assessmentService.GetAllAssessments();
    return Results.Ok(assessments);
});

app.MapGet("/api/assessments/{id:guid}", (Guid id, AssessmentService assessmentService) =>
{
    var assessment = assessmentService.GetAssessment(id);
    return assessment != null ? Results.Ok(assessment) : Results.NotFound();
});

app.MapGet("/api/teachers/{teacherId:guid}/assessments", (
    Guid teacherId, 
    AssessmentService assessmentService) =>
{
    var assessments = assessmentService.GetAssessmentsByTeacher(teacherId);
    return Results.Ok(assessments);
});

app.MapPut("/api/assessments/{id:guid}", (
    Guid id,
    [FromBody] Assessment assessment,
    AssessmentService assessmentService) =>
{
    var updated = assessmentService.UpdateAssessment(id, assessment);
    return updated ? Results.Ok(assessment) : Results.NotFound();
});

app.MapDelete("/api/assessments/{id:guid}", (Guid id, AssessmentService assessmentService) =>
{
    var deleted = assessmentService.DeleteAssessment(id);
    return deleted ? Results.NoContent() : Results.NotFound();
});

// QR Code Generation Endpoints
app.MapGet("/api/assessments/{id:guid}/qrcode/svg", (
    Guid id,
    AssessmentService assessmentService,
    QrCodeService qrCodeService) =>
{
    var assessment = assessmentService.GetAssessment(id);
    if (assessment == null)
        return Results.NotFound();

    var svgContent = qrCodeService.GenerateQrCodeSvg(assessment);
    return Results.Content(svgContent, "image/svg+xml");
});

app.MapGet("/api/assessments/{id:guid}/qrcode/png", (
    Guid id,
    AssessmentService assessmentService,
    QrCodeService qrCodeService,
    [FromQuery] int size = 10) =>
{
    var assessment = assessmentService.GetAssessment(id);
    if (assessment == null)
        return Results.NotFound();

    var pngBytes = qrCodeService.GenerateQrCodePng(assessment, size);
    return Results.File(pngBytes, "image/png");
});

// Answer sheet generation endpoint
app.MapGet("/api/assessments/{id:guid}/answer-sheet", (
    Guid id,
    AssessmentService assessmentService,
    AnswerSheetService answerSheetService) =>
{
    var assessment = assessmentService.GetAssessment(id);
    if (assessment == null)
        return Results.NotFound();

    var answerSheetSvg = answerSheetService.GenerateAnswerSheetSvg(assessment);
    return Results.Content(answerSheetSvg, "image/svg+xml");
});

// Sample data creation endpoint
app.MapPost("/api/sample-data/{teacherId:guid}", (
    Guid teacherId,
    AssessmentService assessmentService) =>
{
    var assessment = assessmentService.CreateSampleAssessment(teacherId);
    return Results.Created($"/api/assessments/{assessment.Id}", assessment);
});

// QR Code validation endpoint (for testing)
app.MapPost("/api/qrcode/validate", (
    [FromBody] ValidateQrCodeRequest request,
    QrCodeService qrCodeService) =>
{
    var isValid = qrCodeService.ValidateQrCode(request.QrCodeContent, out var payload);
    
    if (isValid && payload != null)
    {
        return Results.Ok(new { valid = true, payload });
    }
    
    return Results.Ok(new { valid = false, message = "Invalid or tampered QR code" });
});

app.Run();

// Request DTOs
public record CreateAssessmentRequest(
    [Required] string Name,
    [Required] Guid TeacherId,
    [Required, Range(1, 200)] int QuestionCount,
    [Required] List<string> AnswerKey,
    [Required] Dictionary<string, int> PointValues,
    string? Description = null,
    DateTime? ExpiresAt = null
);

public record ValidateQrCodeRequest([Required] string QrCodeContent);
