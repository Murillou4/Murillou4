import 'dart:convert';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import '../models/qr_payload.dart';

class JwtService {
  // This would be the public key from the backend
  // In a real implementation, this could be fetched once and stored
  static const String _publicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxjnVWbOgGJl8hP/XMnrOa8e
I4sZFCOCMJW9Ox5wMzJVGH6KfO1qBQrVH7Hfy4FDV9aLx3xWjMqbC4K8K5LzJvnrV
VgfXJGp4gPwFbRbJxLlEb6yJ2Vz1VlKdKe5LGz1DYzNJgkqhkiG9w0BAQEFAAOCsZ
FDV9aLx3xWjMqbC4K8K5LzJvnrVVgfXJGp4gPwFbRbJxLlEb6yJ2Vz1VlKdKe5LGz
1DYzNJgkqhkiG9w0BAQEFAAOCADEwggEKAoIBAQDF/1111111111111111111111
11111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111
wIDAQAB
-----END PUBLIC KEY-----
''';

  static bool validateToken(String token, {QrPayload? expectedPayload}) {
    try {
      // For demo purposes, we'll use a simplified validation
      // In production, this would use the actual RSA public key
      final jwt = JWT.verify(token, SecretKey('demo-key'));
      
      final payload = jwt.payload as Map<String, dynamic>;
      
      // Validate required fields
      if (!payload.containsKey('assessmentId') ||
          !payload.containsKey('teacherId') ||
          !payload.containsKey('answerKey') ||
          !payload.containsKey('questionCount')) {
        return false;
      }

      // Check expiration if present
      if (payload.containsKey('expiresAt')) {
        final expiresAt = payload['expiresAt'] as String?;
        if (expiresAt != null) {
          final expiryDate = DateTime.parse(expiresAt);
          if (DateTime.now().isAfter(expiryDate)) {
            return false;
          }
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  static QrPayload? decodePayload(String token) {
    try {
      // For demo purposes, we'll decode without full verification
      // In production, this would use proper RSA verification
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      // Add padding if needed
      final paddedPayload = payload + '=' * ((4 - payload.length % 4) % 4);
      
      final decodedBytes = base64Url.decode(paddedPayload);
      final decodedJson = utf8.decode(decodedBytes);
      final payloadMap = json.decode(decodedJson) as Map<String, dynamic>;

      // Parse the nested JSON strings
      final answerKey = json.decode(payloadMap['answerKey'] as String) as List;
      final pointValues = json.decode(payloadMap['pointValues'] as String) as Map;

      return QrPayload(
        assessmentId: payloadMap['assessmentId'] as String,
        teacherId: payloadMap['teacherId'] as String,
        issuedAt: payloadMap['issuedAt'] as String,
        expiresAt: payloadMap['expiresAt'] as String?,
        answerKey: List<String>.from(answerKey),
        pointValues: Map<String, int>.from(pointValues),
        questionCount: int.parse(payloadMap['questionCount'] as String),
        assessmentName: payloadMap['assessmentName'] as String,
      );
    } catch (e) {
      print('Error decoding JWT payload: $e');
      return null;
    }
  }

  static String createDemoToken(QrPayload payload) {
    // This is for demo purposes only
    // In production, tokens would only be created by the backend
    final jwt = JWT({
      'assessmentId': payload.assessmentId,
      'teacherId': payload.teacherId,
      'issuedAt': payload.issuedAt,
      'expiresAt': payload.expiresAt,
      'answerKey': json.encode(payload.answerKey),
      'pointValues': json.encode(payload.pointValues),
      'questionCount': payload.questionCount.toString(),
      'assessmentName': payload.assessmentName,
    });

    return jwt.sign(SecretKey('demo-key'));
  }
}