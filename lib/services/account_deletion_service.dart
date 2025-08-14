import 'package:firebase_database/firebase_database.dart';
import '../models/deletion_request_model.dart';

class AccountDeletionService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // إنشاء طلب حذف جديد
  Future<DeletionRequestModel> createDeletionRequest(String userId) async {
    try {
      final requestDate = DateTime.now();
      // تاريخ التنفيذ بعد 48 ساعة
      final executionDate = requestDate.add(const Duration(hours: 48));

      final deletionRequest = DeletionRequestModel(
          userId: userId,
          requestDate: requestDate,
          executionDate: executionDate,
          isActive: true
      );

      // حفظ الطلب في Firebase
      await _database.child('deletion_requests').child(userId).set(deletionRequest.toMap());

      // إضافة علامة في بيانات المستخدم
      await _database.child('users').child(userId).update({
        'deletionRequested': true,
        'deletionRequestDate': requestDate.millisecondsSinceEpoch,
      });

      return deletionRequest;
    } catch (e) {
      print('خطأ في إنشاء طلب حذف الحساب: $e');
      throw Exception('فشل في إنشاء طلب حذف الحساب، يرجى المحاولة مرة أخرى لاحقًا');
    }
  }

  // إلغاء طلب حذف الحساب
  Future<void> cancelDeletionRequest(String userId) async {
    try {
      // التحقق من وجود طلب نشط
      final requestSnapshot = await _database.child('deletion_requests').child(userId).get();

      if (requestSnapshot.exists) {
        // إلغاء الطلب بتعديل حالته إلى غير نشط
        await _database.child('deletion_requests').child(userId).update({
          'isActive': false,
        });

        // إزالة العلامة من بيانات المستخدم
        await _database.child('users').child(userId).update({
          'deletionRequested': false,
        });
      }
    } catch (e) {
      print('خطأ في إلغاء طلب حذف الحساب: $e');
      throw Exception('فشل في إلغاء طلب حذف الحساب، يرجى المحاولة مرة أخرى لاحقًا');
    }
  }

  // التحقق من وجود طلب حذف نشط للمستخدم
  Future<DeletionRequestModel?> getActiveDeletionRequest(String userId) async {
    try {
      final requestSnapshot = await _database.child('deletion_requests').child(userId).get();

      if (requestSnapshot.exists && requestSnapshot.value != null) {
        final data = Map<String, dynamic>.from(requestSnapshot.value as Map);
        final request = DeletionRequestModel.fromMap(data);

        // إرجاع الطلب فقط إذا كان نشطًا
        if (request.isActive) {
          return request;
        }
      }

      return null;
    } catch (e) {
      print('خطأ في التحقق من طلب حذف الحساب: $e');
      return null;
    }
  }

  // حذف جميع بيانات المستخدم عند تنفيذ طلب الحذف
  Future<void> executeAccountDeletion(String userId) async {
    try {
      // حذف بيانات المستخدم
      await _database.child('users').child(userId).remove();

      // حذف المستخدم من غرفة الانتظار
      await _database.child('waiting_room').child(userId).remove();

      // إنهاء جميع جلسات المستخدم
      await _endUserSessions(userId);

      // حذف طلب الحذف نفسه
      await _database.child('deletion_requests').child(userId).remove();

      // إضافة سجل بالحذف للتوثيق
      await _database.child('deleted_accounts').push().set({
        'userId': userId,
        'deletedAt': ServerValue.timestamp,
      });

      print('تم تنفيذ حذف الحساب بنجاح للمستخدم: $userId');
    } catch (e) {
      print('خطأ في تنفيذ حذف الحساب: $e');
    }
  }

  // إنهاء جميع جلسات المستخدم
  Future<void> _endUserSessions(String userId) async {
    try {
      // البحث عن الجلسات التي يكون فيها المستخدم مضيفًا
      final hostSnapshot = await _database
          .child('sessions')
          .orderByChild('hostId')
          .equalTo(userId)
          .get();

      if (hostSnapshot.exists && hostSnapshot.value != null) {
        final hostSessions = Map<String, dynamic>.from(hostSnapshot.value as Map);

        for (final entry in hostSessions.entries) {
          await _database.child('sessions').child(entry.key).update({
            'isActive': false,
          });
        }
      }

      // البحث عن الجلسات التي يكون فيها المستخدم ضيفًا
      final guestSnapshot = await _database
          .child('sessions')
          .orderByChild('guestId')
          .equalTo(userId)
          .get();

      if (guestSnapshot.exists && guestSnapshot.value != null) {
        final guestSessions = Map<String, dynamic>.from(guestSnapshot.value as Map);

        for (final entry in guestSessions.entries) {
          await _database.child('sessions').child(entry.key).update({
            'isActive': false,
          });
        }
      }
    } catch (e) {
      print('خطأ في إنهاء جلسات المستخدم: $e');
    }
  }
}
