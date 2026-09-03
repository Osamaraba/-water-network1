import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

enum ShareTarget { whatsappNumber, whatsappDirect, system, save }

class ReportShareService {
  static const String _waScheme = 'whatsapp://send';

  /// Save report bytes to a temp file with a friendly filename.
  static Future<File> saveReportFile(
      List<int> bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Quick helper: save bytes to temp and open the share sheet directly.
  static Future<void> saveAndShareReport(
    BuildContext context,
    List<int> bytes,
    String filename,
    String reportTitle,
  ) async {
    final file = await saveReportFile(bytes, filename);
    if (!context.mounted) return;
    await showShareDialog(context, file: file, reportTitle: reportTitle);
  }

  /// Persist a copy to the user's documents folder for later access.
  static Future<File> saveToDocuments(
      List<int> bytes, String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final reportsDir = Directory('${dir.path}/Reports');
    if (!await reportsDir.exists()) {
      await reportsDir.create(recursive: true);
    }
    final file = File('${reportsDir.path}/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Share the file via WhatsApp to a specific phone number.
  /// Phone number must include country code, e.g. +96279xxxxxxx.
  static Future<bool> shareViaWhatsApp(
    File file, {
    required String phoneNumber,
    String? caption,
  }) async {
    // Normalize the number: strip spaces, dashes; keep + and digits
    final clean = phoneNumber.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^\+?\d{8,15}$').hasMatch(clean)) {
      return false;
    }
    final intl = clean.startsWith('+') ? clean.substring(1) : clean;
    final uri = Uri.parse(
        '$_waScheme?phone=$intl&text=${Uri.encodeComponent(caption ?? "تقرير")}');

    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  /// Share file using the OS share sheet (allows user to pick WhatsApp).
  static Future<void> shareViaSystem(
    File file, {
    String? caption,
  }) async {
    await Share.shareXFiles([XFile(file.path)], text: caption);
  }

  /// Open the file with default app (e.g. WhatsApp if set as default).
  static Future<bool> openFile(File file) async {
    return launchUrl(Uri.file(file.path));
  }

  /// Show a share dialog that lets the user choose:
  /// - WhatsApp to a specific number (typed or picked)
  /// - OS share sheet
  /// - Save to documents
  static Future<void> showShareDialog(
    BuildContext context, {
    required File file,
    required String reportTitle,
  }) async {
    final result = await showModalBottomSheet<ShareTarget>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ShareBottomSheet(reportTitle: reportTitle),
    );

    if (result == null) return;
    if (!context.mounted) return;
    final ctx = context;

    switch (result) {
      case ShareTarget.whatsappNumber:
        final phone = await _askPhoneNumber(ctx);
        if (phone == null) return;
        try {
          final ok = await shareViaWhatsApp(
            file,
            phoneNumber: phone,
            caption: 'تقرير: $reportTitle\nمرسل من تطبيق إدارة مياه اليرموك',
          );
          if (!ok && ctx.mounted) {
            _toast(ctx,
                'تعذر فتح واتساب. تأكد من تثبيته. سيُفتح عبر مشاركة النظام...');
            await shareViaSystem(file, caption: 'تقرير: $reportTitle');
          } else if (ctx.mounted) {
            _toast(ctx, 'تم فتح واتساب لإرسال التقرير إلى $phone', success: true);
          }
        } catch (e) {
          if (ctx.mounted) _toast(ctx, 'خطأ: $e');
        }
        break;
      case ShareTarget.whatsappDirect:
        try {
          await shareViaSystem(file, caption: 'تقرير: $reportTitle');
          if (ctx.mounted) {
            _toast(ctx, 'اختر واتساب من قائمة المشاركة', success: true);
          }
        } catch (e) {
          if (ctx.mounted) _toast(ctx, 'خطأ: $e');
        }
        break;
      case ShareTarget.save:
        try {
          final saved = await saveToDocuments(
              await file.readAsBytes(), file.uri.pathSegments.last);
          if (ctx.mounted) {
            _toast(ctx, 'تم حفظ التقرير في: ${saved.path}', success: true);
          }
        } catch (e) {
          if (ctx.mounted) _toast(ctx, 'تعذر الحفظ: $e');
        }
        break;
      case ShareTarget.system:
        await shareViaSystem(file, caption: 'تقرير: $reportTitle');
        break;
    }
  }

  static Future<String?> _askPhoneNumber(BuildContext context) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.message, color: Color(0xFF25D366)),
              SizedBox(width: 8),
              Text('إرسال عبر واتساب'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('أدخل رقم الهاتف (مع رمز الدولة):'),
              const SizedBox(height: 4),
              Text('مثال: +962791234567',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  hintText: '+962791234567',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('إلغاء'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.send),
              label: const Text('إرسال'),
              onPressed: () {
                final v = ctrl.text.trim();
                if (v.isEmpty) {
                  Navigator.pop(c);
                  return;
                }
                Navigator.pop(c, v);
              },
            ),
          ],
        );
      },
    );
  }

  static void _toast(BuildContext context, String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

class _ShareBottomSheet extends StatelessWidget {
  final String reportTitle;
  const _ShareBottomSheet({required this.reportTitle});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'مشاركة التقرير',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                reportTitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            _ShareTile(
              icon: Icons.message,
              iconColor: const Color(0xFF25D366),
              title: 'إرسال عبر واتساب (رقم محدد)',
              subtitle: 'أدخل رقم هاتف المستلم مباشرة',
              onTap: () => Navigator.pop(context, ShareTarget.whatsappNumber),
            ),
            _ShareTile(
              icon: Icons.share,
              iconColor: const Color(0xFF25D366),
              title: 'مشاركة عبر واتساب (قائمة التطبيقات)',
              subtitle: 'يظهر واتساب في قائمة المشاركة',
              onTap: () => Navigator.pop(context, ShareTarget.whatsappDirect),
            ),
            _ShareTile(
              icon: Icons.save_alt,
              iconColor: Colors.blue,
              title: 'حفظ في مجلد المستندات',
              subtitle: 'للوصول إليه لاحقاً من إدارة الملفات',
              onTap: () => Navigator.pop(context, ShareTarget.save),
            ),
            _ShareTile(
              icon: Icons.ios_share,
              iconColor: Colors.grey[700],
              title: 'مشاركة عامة',
              subtitle: 'يعرض جميع التطبيقات المتاحة',
              onTap: () => Navigator.pop(context, ShareTarget.system),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ShareTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: (iconColor ?? Colors.blue).withValues(alpha: 0.15),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
    );
  }
}
