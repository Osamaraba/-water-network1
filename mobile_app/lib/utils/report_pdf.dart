import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/attendance.dart';

class ReportPdf {
  static Future<pw.Font> _arabicFont() async {
    final bytes = await rootBundle.load('assets/fonts/tahoma.ttf');
    return pw.Font.ttf(bytes);
  }

  static Future<Uint8List> buildBytes({
    required String title,
    String? description,
    required String authorName,
    required String authorNumber,
    required String date,
    String status = '',
    String? whatsappNumber,
  }) async {
    final font = await _arabicFont();
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font),
        build: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('إدارة مياه عجلون',
                    style: pw.TextStyle(fontSize: 20, font: font, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 1.5),
                pw.SizedBox(height: 12),
                pw.Text('نوع التقرير: تقرير يومي',
                    style: pw.TextStyle(fontSize: 14, font: font)),
                pw.SizedBox(height: 8),
                pw.Text('العنوان: $title',
                    style: pw.TextStyle(fontSize: 16, font: font, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('التاريخ: $date',
                    style: pw.TextStyle(fontSize: 13, font: font)),
                pw.SizedBox(height: 8),
                pw.Text('الكاتب: $authorName  (رقم: $authorNumber)',
                    style: pw.TextStyle(fontSize: 13, font: font)),
                if (status.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 8),
                    child: pw.Text('الحالة: $status',
                        style: pw.TextStyle(fontSize: 13, font: font)),
                  ),
                if (whatsappNumber != null && whatsappNumber.trim().isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 8),
                    child: pw.Text('رقم الواتساب: ${whatsappNumber.trim()}',
                        style: pw.TextStyle(fontSize: 13, font: font)),
                  ),
                pw.SizedBox(height: 16),
                pw.Text('التفاصيل:',
                    style: pw.TextStyle(fontSize: 14, font: font, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Expanded(
                  child: pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Text(description?.isNotEmpty == true ? description! : 'لا يوجد',
                        style: pw.TextStyle(fontSize: 13, font: font),
                        textAlign: pw.TextAlign.right),
                  ),
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.Text('تم إنشاء هذا التقرير عبر تطبيق إدارة مياه عجلون',
                    style: pw.TextStyle(fontSize: 10, font: font, color: PdfColors.grey)),
              ],
            ),
          ),
        ),
      ),
    );

    return pdf.save();
  }

  static Future<void> share({
    required String title,
    String? description,
    required String authorName,
    required String authorNumber,
    required String date,
    String status = '',
    String? whatsappNumber,
  }) async {
    final bytes = await buildBytes(
      title: title,
      description: description,
      authorName: authorName,
      authorNumber: authorNumber,
      date: date,
      status: status,
      whatsappNumber: whatsappNumber,
    );
    await Printing.sharePdf(bytes: bytes, filename: 'report_${DateTime.now().millisecondsSinceEpoch}.pdf');
  }

  static Future<void> shareInboxItem(ReportInboxItem item, String currentName, String currentNumber) async {
    await share(
      title: item.title,
      description: item.description,
      authorName: item.authorName.isNotEmpty ? item.authorName : currentName,
      authorNumber: item.authorNumber.isNotEmpty ? item.authorNumber : currentNumber,
      date: item.reportDate ?? item.createdAt,
      status: item.status,
    );
  }

  static Future<void> shareBreaches(List<Map<String, dynamic>> breaches) async {
    final bytes = await buildBreachesBytes(breaches);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'geofence_breaches_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<Uint8List> buildBreachesBytes(
      List<Map<String, dynamic>> breaches) async {
    final font = await _arabicFont();
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font),
        build: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('تقرير خروقات منطقة العمل',
                    style: pw.TextStyle(
                        fontSize: 20, font: font, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 1.5),
                pw.SizedBox(height: 10),
                pw.Table.fromTextArray(
                  context: context,
                  headerStyle: pw.TextStyle(
                      font: font, fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: pw.TextStyle(font: font, fontSize: 9),
                  headers: const [
                    'الموظف',
                    'رقم الموظف',
                    'بداية الخروج',
                    'نهاية الخروج',
                    'المدة',
                    'المسافة (م)'
                  ],
                  data: List<List<String>>.generate(
                    breaches.length,
                    (i) {
                      final b = breaches[i];
                      final start = (b['started_at'] ?? '').toString();
                      final end = (b['ended_at'] ?? '').toString();
                      return [
                        b['full_name'] ?? '',
                        b['employee_number'] ?? '',
                        start.length > 19 ? start.substring(0, 19) : start,
                        end.length > 19 ? end.substring(0, 19) : end,
                        _fmtDurationAr((b['duration_seconds'] ?? 0).toDouble()),
                        (b['distance_m'] ?? 0).toStringAsFixed(0),
                      ];
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return pdf.save();
  }

  static Future<void> shareRoute({
    required String employeeName,
    required String mode,
    required int interval,
    required List<Map<String, dynamic>> points,
    int outsideCount = 0,
    double totalDistanceM = 0,
  }) async {
    final bytes = await buildRouteBytes(
      employeeName: employeeName,
      mode: mode,
      interval: interval,
      points: points,
      outsideCount: outsideCount,
      totalDistanceM: totalDistanceM,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'masir_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<Uint8List> buildRouteBytes({
    required String employeeName,
    required String mode,
    required int interval,
    required List<Map<String, dynamic>> points,
    int outsideCount = 0,
    double totalDistanceM = 0,
  }) async {
    final font = await _arabicFont();
    final modeText = mode == 'time'
        ? 'كل $interval دقيقة'
        : 'كل $interval متر';

    String _fmtDist(double m) {
      if (m >= 1000) return '${(m / 1000).toStringAsFixed(2)} كم';
      return '${m.toStringAsFixed(0)} م';
    }

    String _fmtTime() {
      if (points.length < 2) return 'غير محدد';
      final first = DateTime.tryParse(points.first['recorded_at'] ?? '');
      final last = DateTime.tryParse(points.last['recorded_at'] ?? '');
      if (first == null || last == null) return 'غير محدد';
      final diff = last.difference(first);
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      final s = diff.inSeconds % 60;
      final parts = <String>[];
      if (h > 0) parts.add('$h ساعة');
      if (m > 0) parts.add('$m دقيقة');
      if (s > 0 || parts.isEmpty) parts.add('$s ثانية');
      return parts.join(' ');
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: font),
        build: (context) => pw.Directionality(
          textDirection: pw.TextDirection.rtl,
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('مسار حركة الموظف',
                    style: pw.TextStyle(fontSize: 20, font: font, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 1.5),
                pw.SizedBox(height: 8),
                pw.Text('الموظف: $employeeName',
                    style: pw.TextStyle(fontSize: 14, font: font)),
                pw.Text('وضع التتبع: $modeText',
                    style: pw.TextStyle(fontSize: 13, font: font)),
                pw.SizedBox(height: 6),
                pw.Row(children: [
                  pw.Text('عدد النقاط: ${points.length}  |  ',
                      style: pw.TextStyle(fontSize: 12, font: font)),
                  pw.Text('المسافة: ${_fmtDist(totalDistanceM)}  |  ',
                      style: pw.TextStyle(fontSize: 12, font: font)),
                  pw.Text('المدة: ${_fmtTime()}',
                      style: pw.TextStyle(fontSize: 12, font: font)),
                ]),
                if (outsideCount > 0)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text('عدد مرات الخروج من المنطقة: $outsideCount',
                        style: pw.TextStyle(fontSize: 12, font: font, color: PdfColors.red)),
                  ),
                pw.SizedBox(height: 12),
                pw.Container(
                  height: 220,
                  width: double.infinity,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: points.length < 2
                      ? pw.Center(
                          child: pw.Text('لا توجد نقاط كافية لرسم المسار',
                              style: pw.TextStyle(fontSize: 12, font: font)))
                      : pw.CustomPaint(
                          painter: (g, size) => _paintRoute(g, size, points)),
                ),
                pw.SizedBox(height: 12),
                pw.Text('تفاصيل الإحداثيات:',
                    style: pw.TextStyle(
                        fontSize: 14, font: font, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Table.fromTextArray(
                  context: context,
                  headerStyle: pw.TextStyle(
                      font: font, fontWeight: pw.FontWeight.bold, fontSize: 10),
                  cellStyle: pw.TextStyle(font: font, fontSize: 9),
                  headers: const ['#', 'الوقت', 'خط العرض', 'خط الطول', 'الدقة (م)'],
                  data: List<List<String>>.generate(
                    points.length,
                    (i) {
                      final p = points[i];
                      final t = (p['recorded_at'] ?? '').toString();
                      final lat = (p['latitude'] ?? '').toString();
                      final lng = (p['longitude'] ?? '').toString();
                      final acc = (p['accuracy'] ?? '').toString();
                      return [
                        '${i + 1}',
                        t.length > 19 ? t.substring(0, 19) : t,
                        lat,
                        lng,
                        acc,
                      ];
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return pdf.save();
  }
}

String _fmtDurationAr(double seconds) {
  final s = seconds.toInt();
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  final parts = <String>[];
  if (h > 0) parts.add('$h ساعة');
  if (m > 0) parts.add('$m دقيقة');
  if (sec > 0 || parts.isEmpty) parts.add('$sec ثانية');
  return parts.join(' و ');
}

void _paintRoute(PdfGraphics g, PdfPoint size, List<Map<String, dynamic>> points) {
  if (points.length < 2) return;
  final lats = points.map((p) => (p['latitude'] as num).toDouble()).toList();
  final lngs = points.map((p) => (p['longitude'] as num).toDouble()).toList();
  final minLat = lats.reduce(math.min);
  final maxLat = lats.reduce(math.max);
  final minLng = lngs.reduce(math.min);
  final maxLng = lngs.reduce(math.max);
  final pad = 12.0;
  final w = size.x;
  final h = size.y;

  double sx(double lng) {
    if (maxLng == minLng) return w / 2;
    return ((lng - minLng) / (maxLng - minLng)) * (w - 2 * pad) + pad;
  }

  double sy(double lat) {
    if (maxLat == minLat) return h / 2;
    return h - (((lat - minLat) / (maxLat - minLat)) * (h - 2 * pad) + pad);
  }

  g.setColor(PdfColors.blue);
  g.setLineWidth(2);
  for (int i = 0; i < points.length - 1; i++) {
    g.drawLine(sx(lngs[i]), sy(lats[i]), sx(lngs[i + 1]), sy(lats[i + 1]));
  }
  g.setColor(PdfColors.green);
  g.drawEllipse(sx(lngs.first), sy(lats.first), 4, 4);
  g.fillPath();
  g.setColor(PdfColors.red);
  g.drawEllipse(sx(lngs.last), sy(lats.last), 4, 4);
  g.fillPath();
}
