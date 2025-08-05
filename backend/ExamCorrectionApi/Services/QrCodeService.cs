using QRCoder;
using ExamCorrectionApi.Models;

namespace ExamCorrectionApi.Services;

public class QrCodeService
{
    private readonly SecurityService _securityService;

    public QrCodeService(SecurityService securityService)
    {
        _securityService = securityService;
    }

    public string GenerateQrCodeSvg(Assessment assessment)
    {
        var payload = new QrCodePayload
        {
            AssessmentId = assessment.Id.ToString(),
            TeacherId = assessment.TeacherId.ToString(),
            IssuedAt = DateTime.UtcNow.ToString("O"),
            ExpiresAt = assessment.ExpiresAt?.ToString("O"),
            AnswerKey = assessment.AnswerKey,
            PointValues = assessment.PointValues,
            QuestionCount = assessment.QuestionCount,
            AssessmentName = assessment.Name
        };

        var signedToken = _securityService.CreateSignedToken(payload);

        using var qrGenerator = new QRCodeGenerator();
        using var qrCodeData = qrGenerator.CreateQrCode(signedToken, QRCodeGenerator.ECCLevel.M);
        using var qrCode = new SvgQRCode(qrCodeData);
        
        return qrCode.GetGraphic(20, "#000000", "#FFFFFF", true);
    }

    public byte[] GenerateQrCodePng(Assessment assessment, int pixelsPerModule = 10)
    {
        var payload = new QrCodePayload
        {
            AssessmentId = assessment.Id.ToString(),
            TeacherId = assessment.TeacherId.ToString(),
            IssuedAt = DateTime.UtcNow.ToString("O"),
            ExpiresAt = assessment.ExpiresAt?.ToString("O"),
            AnswerKey = assessment.AnswerKey,
            PointValues = assessment.PointValues,
            QuestionCount = assessment.QuestionCount,
            AssessmentName = assessment.Name
        };

        var signedToken = _securityService.CreateSignedToken(payload);

        using var qrGenerator = new QRCodeGenerator();
        using var qrCodeData = qrGenerator.CreateQrCode(signedToken, QRCodeGenerator.ECCLevel.M);
        using var qrCode = new PngByteQRCode(qrCodeData);
        
        return qrCode.GetGraphic(pixelsPerModule);
    }

    public bool ValidateQrCode(string qrCodeContent, out QrCodePayload? payload)
    {
        return _securityService.ValidateToken(qrCodeContent, out payload);
    }
}