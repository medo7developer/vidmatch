import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../models/user_model.dart';
import '../models/filter_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _userId;
  String _userName = '';
  String _country = '';
  String _gender = '';
  bool _isAdult = false;
  bool _acceptedTerms = false;
  bool _isRegistered = false;
  FilterPreferences _filterPreferences = FilterPreferences();

  // Getters
  String? get userId => _userId;
  String get userName => _userName;
  String get country => _country;
  String get gender => _gender;
  bool get isAdult => _isAdult;
  bool get acceptedTerms => _acceptedTerms;
  bool get isRegistered => _isRegistered;
  bool get isAuthenticated => _userId != null && _isAdult && _acceptedTerms && _isRegistered;
  FilterPreferences get filterPreferences => _filterPreferences;

  AuthProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    _userName = prefs.getString('userName') ?? '';
    _country = prefs.getString('country') ?? '';
    _gender = prefs.getString('gender') ?? '';
    _isAdult = prefs.getBool('isAdult') ?? false;
    _acceptedTerms = prefs.getBool('acceptedTerms') ?? false;
    _isRegistered = prefs.getBool('isRegistered') ?? false;

    // تحميل تفضيلات التصفية
    final filterByGender = prefs.getBool('filterByGender') ?? false;
    final preferredGender = prefs.getString('preferredGender') ?? 'الكل';
    final filterByCountry = prefs.getBool('filterByCountry') ?? false;
    final preferredCountry = prefs.getString('preferredCountry') ?? 'الكل';
    final useVideoFilters = prefs.getBool('useVideoFilters') ?? false;
    final activeFilter = prefs.getString('activeFilter') ?? 'none';

    _filterPreferences = FilterPreferences(
      filterByGender: filterByGender,
      preferredGender: preferredGender,
      filterByCountry: filterByCountry,
      preferredCountry: preferredCountry,
      useVideoFilters: useVideoFilters,
      activeFilter: activeFilter,
    );

    notifyListeners();
  }

  Future<void> generateUserId() async {
    final prefs = await SharedPreferences.getInstance();

    if (_userId == null) {
      final random = Random();
      _userId = DateTime.now().millisecondsSinceEpoch.toString() +
          random.nextInt(10000).toString();

      await prefs.setString('userId', _userId!);
      notifyListeners();
    }
  }

  Future<void> registerUser({
    required String name,
    required String country,
    required String gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    _userName = name;
    _country = country;
    _gender = gender;
    _isRegistered = true;

    await prefs.setString('userName', name);
    await prefs.setString('country', country);
    await prefs.setString('gender', gender);
    await prefs.setBool('isRegistered', true);

    notifyListeners();
  }

  Future<void> confirmAdultAge(bool isAdult) async {
    final prefs = await SharedPreferences.getInstance();
    _isAdult = isAdult;
    await prefs.setBool('isAdult', isAdult);
    notifyListeners();
  }

  Future<void> acceptTerms(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    _acceptedTerms = accepted;
    await prefs.setBool('acceptedTerms', accepted);
    notifyListeners();
  }

  Future<void> updateFilterPreferences(FilterPreferences preferences) async {
    final prefs = await SharedPreferences.getInstance();

    _filterPreferences = preferences;

    // حفظ التفضيلات
    await prefs.setBool('filterByGender', preferences.filterByGender);
    await prefs.setString('preferredGender', preferences.preferredGender);
    await prefs.setBool('filterByCountry', preferences.filterByCountry);
    await prefs.setString('preferredCountry', preferences.preferredCountry);
    await prefs.setBool('useVideoFilters', preferences.useVideoFilters);
    await prefs.setString('activeFilter', preferences.activeFilter);

    notifyListeners();
  }

  // تحديث فلتر الفيديو فقط
  Future<void> updateVideoFilter(String filter) async {
    final prefs = await SharedPreferences.getInstance();

    _filterPreferences = _filterPreferences.copyWith(
      activeFilter: filter,
      useVideoFilters: filter != 'none',
    );

    await prefs.setString('activeFilter', filter);
    await prefs.setBool('useVideoFilters', filter != 'none');

    notifyListeners();
  }

  // إنشاء كائن نموذج المستخدم
  UserModel createUserModel() {
    return UserModel(
      id: _userId ?? '',
      name: _userName,
      country: _country,
      gender: _gender,
      isAvailable: true,
      lastSeen: DateTime.now(),
      preferences: _filterPreferences.toMap(),
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    // تنظيف البيانات من Firebase قبل تسجيل الخروج
    if (_userId != null) {
      try {
        // تحديث حالة المستخدم إلى غير متاح
        await FirebaseDatabase.instance.ref()
            .child('users')
            .child(_userId!)
            .update({'isAvailable': false});

        // إزالة المستخدم من غرفة الانتظار
        await FirebaseDatabase.instance.ref()
            .child('waiting_room')
            .child(_userId!)
            .remove();
      } catch (e) {
        print('خطأ في تنظيف بيانات المستخدم عند تسجيل الخروج: $e');
      }
    }

    // لا نمسح userId لأننا نريد الاحتفاظ به
    await prefs.remove('isAdult');
    await prefs.remove('acceptedTerms');
    await prefs.remove('isRegistered');
    await prefs.remove('userName');
    await prefs.remove('country');
    await prefs.remove('gender');

    _isAdult = false;
    _acceptedTerms = false;
    _isRegistered = false;
    _userName = '';
    _country = '';
    _gender = '';

    notifyListeners();
  }

  Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();

    // حذف جميع البيانات المخزنة محلياً
    await prefs.clear();

    // إعادة تعيين المتغيرات
    _isAdult = false;
    _acceptedTerms = false;
    _isRegistered = false;
    _userName = '';
    _country = '';
    _gender = '';

    // لا تقم بإعادة تعيين userId لأننا سنستخدمه للتحقق من طلب الحذف

    notifyListeners();
  }
}
