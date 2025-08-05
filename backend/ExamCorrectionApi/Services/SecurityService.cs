using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using Microsoft.IdentityModel.Tokens;
using System.Text.Json;
using ExamCorrectionApi.Models;

namespace ExamCorrectionApi.Services;

public class SecurityService
{
    private readonly RSA _rsa;
    private readonly RsaSecurityKey _privateKey;
    private readonly RsaSecurityKey _publicKey;
    private readonly JwtSecurityTokenHandler _tokenHandler;

    public SecurityService()
    {
        _rsa = RSA.Create(2048);
        _privateKey = new RsaSecurityKey(_rsa);
        _publicKey = new RsaSecurityKey(_rsa.ExportParameters(false));
        _tokenHandler = new JwtSecurityTokenHandler();
    }

    public string CreateSignedToken(QrCodePayload payload)
    {
        var claims = new List<Claim>
        {
            new("assessmentId", payload.AssessmentId),
            new("teacherId", payload.TeacherId),
            new("issuedAt", payload.IssuedAt),
            new("answerKey", JsonSerializer.Serialize(payload.AnswerKey)),
            new("pointValues", JsonSerializer.Serialize(payload.PointValues)),
            new("questionCount", payload.QuestionCount.ToString()),
            new("assessmentName", payload.AssessmentName)
        };

        if (!string.IsNullOrEmpty(payload.ExpiresAt))
        {
            claims.Add(new Claim("expiresAt", payload.ExpiresAt));
        }

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = payload.ExpiresAt != null ? DateTime.Parse(payload.ExpiresAt) : DateTime.UtcNow.AddYears(1),
            SigningCredentials = new SigningCredentials(_privateKey, SecurityAlgorithms.RsaSha256),
            Issuer = "ExamCorrectionApi",
            Audience = "ExamCorrectionMobileApp"
        };

        var token = _tokenHandler.CreateToken(tokenDescriptor);
        return _tokenHandler.WriteToken(token);
    }

    public bool ValidateToken(string token, out QrCodePayload? payload)
    {
        payload = null;
        
        try
        {
            var validationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = _publicKey,
                ValidateIssuer = true,
                ValidIssuer = "ExamCorrectionApi",
                ValidateAudience = true,
                ValidAudience = "ExamCorrectionMobileApp",
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            };

            var principal = _tokenHandler.ValidateToken(token, validationParameters, out var validatedToken);
            
            payload = new QrCodePayload
            {
                AssessmentId = principal.FindFirst("assessmentId")?.Value ?? string.Empty,
                TeacherId = principal.FindFirst("teacherId")?.Value ?? string.Empty,
                IssuedAt = principal.FindFirst("issuedAt")?.Value ?? string.Empty,
                ExpiresAt = principal.FindFirst("expiresAt")?.Value,
                AnswerKey = JsonSerializer.Deserialize<List<string>>(principal.FindFirst("answerKey")?.Value ?? "[]") ?? new(),
                PointValues = JsonSerializer.Deserialize<Dictionary<string, int>>(principal.FindFirst("pointValues")?.Value ?? "{}") ?? new(),
                QuestionCount = int.Parse(principal.FindFirst("questionCount")?.Value ?? "0"),
                AssessmentName = principal.FindFirst("assessmentName")?.Value ?? string.Empty
            };

            return true;
        }
        catch
        {
            return false;
        }
    }

    public string GetPublicKeyPem()
    {
        var publicKeyBytes = _publicKey.Rsa.ExportRSAPublicKey();
        return Convert.ToBase64String(publicKeyBytes);
    }

    public void Dispose()
    {
        _rsa?.Dispose();
    }
}