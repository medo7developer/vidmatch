import 'package:firebase_database/firebase_database.dart';
import '../models/report_model.dart';

class ReportService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // إرسال بلاغ عن مستخدم محدد
  Future<String> submitReport({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String details = '',
    required String sessionId,
  }) async {
    try {
      final reportRef = _database.child('reports').push();
      final reportId = reportRef.key!;

      final report = ReportModel(
        id: reportId,
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        reason: reason,
        details: details,
        createdAt: DateTime.now(),
        sessionId: sessionId,
      );

      await reportRef.set(report.toMap());

      // زيادة عداد البلاغات للمستخدم المُبلغ عنه
      await _incrementReportCount(reportedUserId);

      // توثيق البلاغ في هيكل السجل
      await _logReport(reporterId, reportedUserId, reason);

      return reportId;
    } catch (e) {
      print('خطأ في إرسال البلاغ: $e');
      throw Exception('فشل في إرسال البلاغ، يرجى المحاولة مرة أخرى لاحقًا');
    }
  }

  // إرسال بلاغ عام (بدون مستخدم محدد)
  Future<String> submitGeneralReport({
    required String reporterId,
    required String reason,
    String details = '',
  }) async {
    try {
      final reportRef = _database.child('general_reports').push();
      final reportId = reportRef.key!;

      final generalReport = {
        'id': reportId,
        'reporterId': reporterId,
        'reason': reason,
        'details': details,
        'createdAt': ServerValue.timestamp,
        'status': 'pending', // حالة البلاغ: pending, reviewed, resolved
        'type': 'general',
      };

      await reportRef.set(generalReport);

      // توثيق البلاغ العام في سجل البلاغات
      await _logGeneralReport(reporterId, reason);

      return reportId;
    } catch (e) {
      print('خطأ في إرسال البلاغ العام: $e');
      throw Exception('فشل في إرسال البلاغ، يرجى المحاولة مرة أخرى لاحقًا');
    }
  }

  // زيادة عداد البلاغات للمستخدم
  Future<void> _incrementReportCount(String userId) async {
    try {
      final userRef = _database.child('users').child(userId);
      final snapshot = await userRef.child('reportCount').get();

      int reportCount = 0;
      if (snapshot.exists) {
        reportCount = (snapshot.value as int?) ?? 0;
      }

      await userRef.update({'reportCount': reportCount + 1});

      // إذا وصلت البلاغات إلى 5 أو أكثر، ضع علامة على المستخدم
      if (reportCount + 1 >= 5) {
        await userRef.update({'flagged': true});
      }
    } catch (e) {
      print('خطأ في زيادة عداد البلاغات: $e');
    }
  }

  // توثيق البلاغ عن مستخدم في سجل البلاغات
  Future<void> _logReport(String reporterId, String reportedUserId, String reason) async {
    try {
      await _database.child('report_logs').push().set({
        'reporterId': reporterId,
        'reportedUserId': reportedUserId,
        'reason': reason,
        'timestamp': ServerValue.timestamp,
        'type': 'user_report',
      });
    } catch (e) {
      print('خطأ في توثيق البلاغ: $e');
    }
  }

  // توثيق البلاغ العام في سجل البلاغات
  Future<void> _logGeneralReport(String reporterId, String reason) async {
    try {
      await _database.child('report_logs').push().set({
        'reporterId': reporterId,
        'reason': reason,
        'timestamp': ServerValue.timestamp,
        'type': 'general_report',
      });
    } catch (e) {
      print('خطأ في توثيق البلاغ العام: $e');
    }
  }

  // التحقق من حالة مستخدم (هل تم الإبلاغ عنه كثيرًا؟)
  Future<bool> isUserFlagged(String userId) async {
    try {
      final snapshot = await _database.child('users').child(userId).child('flagged').get();
      return snapshot.value == true;
    } catch (e) {
      print('خطأ في التحقق من حالة المستخدم: $e');
      return false;
    }
  }

  // الحصول على البلاغات الخاصة بمستخدم معين (للإدارة)
  Future<List<Map<String, dynamic>>> getUserReports(String userId) async {
    try {
      final snapshot = await _database
          .child('reports')
          .orderByChild('reportedUserId')
          .equalTo(userId)
          .get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.values.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('خطأ في جلب البلاغات: $e');
      return [];
    }
  }

  // الحصول على البلاغات العامة (للإدارة)
  Future<List<Map<String, dynamic>>> getGeneralReports({
    String status = 'all', // all, pending, reviewed, resolved
    int limit = 50,
  }) async {
    try {
      Query query = _database.child('general_reports');

      if (status != 'all') {
        query = query.orderByChild('status').equalTo(status);
      }

      query = query.limitToLast(limit);

      final snapshot = await query.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.values.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    } catch (e) {
      print('خطأ في جلب البلاغات العامة: $e');
      return [];
    }
  }

  // تحديث حالة البلاغ العام (للإدارة)
  Future<void> updateGeneralReportStatus(String reportId, String status) async {
    try {
      await _database.child('general_reports').child(reportId).update({
        'status': status,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('خطأ في تحديث حالة البلاغ: $e');
      throw Exception('فشل في تحديث حالة البلاغ');
    }
  }

  // إحصائيات البلاغات (للإدارة)
  Future<Map<String, int>> getReportStatistics() async {
    try {
      final userReportsSnapshot = await _database.child('reports').get();
      final generalReportsSnapshot = await _database.child('general_reports').get();

      int userReportsCount = 0;
      int generalReportsCount = 0;
      int pendingGeneralReports = 0;

      if (userReportsSnapshot.exists) {
        final data = userReportsSnapshot.value as Map<dynamic, dynamic>;
        userReportsCount = data.length;
      }

      if (generalReportsSnapshot.exists) {
        final data = generalReportsSnapshot.value as Map<dynamic, dynamic>;
        generalReportsCount = data.length;

        // عد البلاغات المعلقة
        for (var report in data.values) {
          if (report['status'] == 'pending') {
            pendingGeneralReports++;
          }
        }
      }

      return {
        'userReports': userReportsCount,
        'generalReports': generalReportsCount,
        'pendingGeneralReports': pendingGeneralReports,
        'totalReports': userReportsCount + generalReportsCount,
      };
    } catch (e) {
      print('خطأ في جلب إحصائيات البلاغات: $e');
      return {
        'userReports': 0,
        'generalReports': 0,
        'pendingGeneralReports': 0,
        'totalReports': 0,
      };
    }
  }

  // حذف بلاغ (للإدارة)
  Future<void> deleteReport(String reportId, {bool isGeneral = false}) async {
    try {
      if (isGeneral) {
        await _database.child('general_reports').child(reportId).remove();
      } else {
        await _database.child('reports').child(reportId).remove();
      }
    } catch (e) {
      print('خطأ في حذف البلاغ: $e');
      throw Exception('فشل في حذف البلاغ');
    }
  }
}