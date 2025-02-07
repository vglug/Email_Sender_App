import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:io';

class EmailService {
  static const String smtpServer = 'smtp.gmail.com';
  static const int smtpPort = 587;
  static const String username = 'seenuthiruvpm@gmail.com';
  static const String password = 'tagy orrf nwzj azwn';
  static const String defaultFromEmail = 'noreply@sam.com';
  static const String defaultToEmail = 'seenuthiruvpm@gmail.com';

  Future<void> sendEmail({
    required String subject,
    required String body,
    required List<String> recipients,
    List<String>? attachments,
  }) async {
    final smtpServer = SmtpServer(
      EmailService.smtpServer,
      port: EmailService.smtpPort,
      username: EmailService.username,
      password: EmailService.password,
    );

    final message = Message()
      ..from = Address(username, 'Your Name')
      ..recipients.addAll(recipients)
      ..subject = subject
      ..text = body;

    // Add attachments if any
    if (attachments != null) {
      for (String path in attachments) {
        final file = File(path);
        if (await file.exists()) {
          final attachment = FileAttachment(file);
          message.attachments.add(attachment);
        }
      }
    }

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } catch (e) {
      print('Error sending email: $e');
      throw e;
    }
  }
} 