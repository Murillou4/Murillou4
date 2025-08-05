using ExamCorrectionApi.Models;
using System.Text;

namespace ExamCorrectionApi.Services;

public class AnswerSheetService
{
    private readonly QrCodeService _qrCodeService;

    public AnswerSheetService(QrCodeService qrCodeService)
    {
        _qrCodeService = qrCodeService;
    }

    public string GenerateAnswerSheetSvg(Assessment assessment)
    {
        const int pageWidth = 595; // A4 width in points
        const int pageHeight = 842; // A4 height in points
        const int margin = 50;
        const int bubbleSize = 16;
        const int bubbleSpacing = 25;
        const int questionSpacing = 30;
        const int optionsPerRow = 5; // A, B, C, D, E

        var svg = new StringBuilder();
        
        // SVG header
        svg.AppendLine($@"<svg width=""{pageWidth}"" height=""{pageHeight}"" xmlns=""http://www.w3.org/2000/svg"">");
        
        // Background
        svg.AppendLine($@"<rect width=""{pageWidth}"" height=""{pageHeight}"" fill=""white"" stroke=""black"" stroke-width=""1""/>");

        // Title
        svg.AppendLine($@"<text x=""{pageWidth / 2}"" y=""40"" text-anchor=""middle"" font-size=""20"" font-weight=""bold"">{assessment.Name}</text>");

        // QR Code
        var qrCodeSvg = _qrCodeService.GenerateQrCodeSvg(assessment);
        var qrCodeSize = 150;
        var qrCodeX = pageWidth - margin - qrCodeSize;
        var qrCodeY = 60;
        
        // Extract the path from QR code SVG and embed it
        svg.AppendLine($@"<g transform=""translate({qrCodeX}, {qrCodeY}) scale(0.5)"">");
        svg.AppendLine(ExtractQrCodePath(qrCodeSvg));
        svg.AppendLine("</g>");

        // Instructions
        var instructionsY = 80;
        svg.AppendLine($@"<text x=""{margin}"" y=""{instructionsY}"" font-size=""12"" font-weight=""bold"">INSTRUÇÕES:</text>");
        svg.AppendLine($@"<text x=""{margin}"" y=""{instructionsY + 15}"" font-size=""10"">1. Use caneta preta ou azul</text>");
        svg.AppendLine($@"<text x=""{margin}"" y=""{instructionsY + 28}"" font-size=""10"">2. Preencha completamente as bolhas</text>");
        svg.AppendLine($@"<text x=""{margin}"" y=""{instructionsY + 41}"" font-size=""10"">3. Não faça rasuras</text>");

        // Student info section
        var studentInfoY = instructionsY + 60;
        svg.AppendLine($@"<text x=""{margin}"" y=""{studentInfoY}"" font-size=""12"" font-weight=""bold"">IDENTIFICAÇÃO DO ALUNO:</text>");
        
        // Student name line
        var nameLineY = studentInfoY + 20;
        svg.AppendLine($@"<text x=""{margin}"" y=""{nameLineY}"" font-size=""10"">Nome: </text>");
        svg.AppendLine($@"<line x1=""{margin + 40}"" y1=""{nameLineY}"" x2=""{pageWidth - margin - qrCodeSize - 20}"" y2=""{nameLineY}"" stroke=""black"" stroke-width=""1""/>");

        // Student ID line
        var idLineY = nameLineY + 25;
        svg.AppendLine($@"<text x=""{margin}"" y=""{idLineY}"" font-size=""10"">Matrícula: </text>");
        svg.AppendLine($@"<line x1=""{margin + 60}"" y1=""{idLineY}"" x2=""{margin + 200}"" y2=""{idLineY}"" stroke=""black"" stroke-width=""1""/>");

        // Fiducial markers (corner markers for perspective correction)
        var markerSize = 20;
        var markerOffset = 15;
        
        // Top-left
        svg.AppendLine($@"<rect x=""{markerOffset}"" y=""{markerOffset}"" width=""{markerSize}"" height=""{markerSize}"" fill=""black""/>");
        // Top-right
        svg.AppendLine($@"<rect x=""{pageWidth - markerOffset - markerSize}"" y=""{markerOffset}"" width=""{markerSize}"" height=""{markerSize}"" fill=""black""/>");
        // Bottom-left
        svg.AppendLine($@"<rect x=""{markerOffset}"" y=""{pageHeight - markerOffset - markerSize}"" width=""{markerSize}"" height=""{markerSize}"" fill=""black""/>");
        // Bottom-right
        svg.AppendLine($@"<rect x=""{pageWidth - markerOffset - markerSize}"" y=""{pageHeight - markerOffset - markerSize}"" width=""{markerSize}"" height=""{markerSize}"" fill=""black""/>");

        // Answer grid
        var gridStartY = idLineY + 40;
        var questionsPerColumn = 25;
        var currentX = margin;
        var currentY = gridStartY;

        svg.AppendLine($@"<text x=""{currentX}"" y=""{currentY - 10}"" font-size=""12"" font-weight=""bold"">RESPOSTAS:</text>");

        for (int questionIndex = 0; questionIndex < assessment.QuestionCount; questionIndex++)
        {
            // Start new column if needed
            if (questionIndex > 0 && questionIndex % questionsPerColumn == 0)
            {
                currentX += 150;
                currentY = gridStartY;
            }

            var questionNumber = questionIndex + 1;
            
            // Question number
            svg.AppendLine($@"<text x=""{currentX}"" y=""{currentY + 12}"" font-size=""10"" font-weight=""bold"">{questionNumber:D2}.</text>");

            // Answer options (A, B, C, D, E)
            for (int optionIndex = 0; optionIndex < optionsPerRow; optionIndex++)
            {
                var option = (char)('A' + optionIndex);
                var bubbleX = currentX + 25 + (optionIndex * bubbleSpacing);
                var bubbleY = currentY;

                // Option letter
                svg.AppendLine($@"<text x=""{bubbleX + bubbleSize / 2}"" y=""{bubbleY - 3}"" text-anchor=""middle"" font-size=""8"">{option}</text>");
                
                // Bubble circle
                svg.AppendLine($@"<circle cx=""{bubbleX + bubbleSize / 2}"" cy=""{bubbleY + bubbleSize / 2}"" r=""{bubbleSize / 2 - 1}"" fill=""white"" stroke=""black"" stroke-width=""1""/>");
            }

            currentY += questionSpacing;

            // If we're getting close to the bottom, start a new column
            if (currentY > pageHeight - 100)
            {
                currentX += 150;
                currentY = gridStartY;
            }
        }

        // Footer with metadata
        var footerY = pageHeight - 30;
        svg.AppendLine($@"<text x=""{margin}"" y=""{footerY}"" font-size=""8"">Prova: {assessment.Id} | Questões: {assessment.QuestionCount} | Gerado em: {DateTime.Now:dd/MM/yyyy HH:mm}</text>");

        svg.AppendLine("</svg>");
        
        return svg.ToString();
    }

    private string ExtractQrCodePath(string qrCodeSvg)
    {
        // This is a simplified extraction - in a real implementation,
        // you'd parse the SVG properly to extract the path elements
        try
        {
            var startIndex = qrCodeSvg.IndexOf("<path");
            if (startIndex == -1) return "";
            
            var endIndex = qrCodeSvg.IndexOf("</svg>", startIndex);
            if (endIndex == -1) endIndex = qrCodeSvg.Length;
            
            return qrCodeSvg.Substring(startIndex, endIndex - startIndex);
        }
        catch
        {
            // Fallback: return a simple QR placeholder
            return @"<rect x=""0"" y=""0"" width=""300"" height=""300"" fill=""black""/><rect x=""10"" y=""10"" width=""280"" height=""280"" fill=""white""/><text x=""150"" y=""160"" text-anchor=""middle"" font-size=""20"" fill=""black"">QR CODE</text>";
        }
    }
}