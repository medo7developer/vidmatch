import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../providers/auth_provider.dart';
import '../providers/session_provider.dart';
import '../providers/webrtc_provider.dart';
import '../models/session_model.dart';
import '../services/ad_service.dart';
import '../services/permission_service.dart';
import '../widgets/permission_handler.dart';
import '../widgets/report_dialog.dart';
import '../widgets/search_animation_widget.dart';
import '../widgets/user_info_card.dart';
import '../widgets/action_buttons.dart';
import '../widgets/user_preview_dialog.dart';
import '../widgets/video_filters.dart';
import '../widgets/video_renderer.dart' as videoRender;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class VideoChatScreen extends StatefulWidget {
  const VideoChatScreen({Key? key}) : super(key: key);

  @override
  State<VideoChatScreen> createState() => _VideoChatScreenState();
}

class _VideoChatScreenState extends State<VideoChatScreen>
    with WidgetsBindingObserver {
  final _database = FirebaseDatabase.instance.ref();

// أضف هذه المتغيرات في _VideoChatScreenState
  String? _matchedUserId;
  bool _showingUserPreview = false;

  // أضف هذه المتغيرات في أعلى _VideoChatScreenState
  bool _shouldContinueSearching = false;
  bool _isInSearchMode = false;
  Timer? _continuousSearchTimer;

  bool _isInitializing = true;
  bool _isConnecting = false;
  bool _isPermissionGranted = false;
  bool _isWaitingForMatch = false;
  String? _errorMessage;
  Timer? _waitingRoomTimer;
  Timer? _connectionCheckTimer;
  StreamSubscription? _waitingRoomSubscription;
  StreamSubscription? _sessionSubscription;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 3;

  // متغيرات جديدة
  bool _showFilters = false;
  bool _showRemoteInfo = false;
  String _remoteUserName = "";
  String _remoteUserCountry = "";
  String _remoteUserGender = "";
  bool _showBottomBanner = true;
  int _sessionDuration = 0;
  Timer? _sessionTimer;

// إضافة متغير جديد في _VideoChatScreenState
  StreamSubscription? _callEndSubscription;

  // معلومات الاتصال للتشخيص
  String _connectionState = "غير متصل";
  String _iceConnectionState = "غير متصل";

  SessionModel? _currentSession;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();

    // إضافة مراقبة دورية للحالة
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _ensureSearchContinues();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // معالجة حالات الخروج والعودة للتطبيق
    if (state == AppLifecycleState.paused) {
      // التطبيق في الخلفية، إيقاف الكاميرا مؤقتًا
      final webrtcProvider = context.read<WebRTCProvider>();
      if (webrtcProvider.isCameraEnabled) {
        webrtcProvider.toggleCamera();
      }
    } else if (state == AppLifecycleState.resumed) {
      // عاد التطبيق إلى الواجهة، فحص الاتصال
      _checkConnectionStatus();
    }
  }

  Future<void> _initialize() async {
    try {
      // تهيئة WebRTC
      final webrtcProvider = context.read<WebRTCProvider>();
      await webrtcProvider.initRenderers();

      // تحقق من بنية قاعدة البيانات
      final sessionProvider = context.read<SessionProvider>();
      await sessionProvider.checkDatabaseStructure();

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في تهيئة مكتبة الدردشة: $e';
        _isInitializing = false;
      });
      print('خطأ في التهيئة: $e');
    }
  }

  void _startConnectionMonitoring() {
    // إلغاء المؤقت السابق إن وجد
    _connectionCheckTimer?.cancel();

    // بدء مراقبة حالة الاتصال كل 5 ثوانٍ
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkConnectionStatus();
    });
  }

  void _checkConnectionStatus() {
    final webrtcProvider = context.read<WebRTCProvider>();

    if (mounted && webrtcProvider.isConnectionEstablished) {
      setState(() {
        _connectionState = "متصل";
        _iceConnectionState = "نشط";
      });
    } else if (_isWaitingForMatch) {
      setState(() {
        _connectionState = "في انتظار مستخدم";
      });
    } else if (_isConnecting) {
      setState(() {
        _connectionState = "جاري الاتصال";
      });
    }
  }

  Future<void> _connectToRandomUser() async {
    if (_isConnecting && _shouldContinueSearching) return;

    setState(() {
      _isConnecting = true;
      _isWaitingForMatch = true; // تأكد من البقاء في وضع البحث
      _shouldContinueSearching = true;
      _isInSearchMode = true;
      _errorMessage = null;
      _reconnectAttempts = 0;
      _isReconnecting = false;
      _remoteUserName = "";
      _remoteUserCountry = "";
      _remoteUserGender = "";
    });

    // بدء البحث المستمر
    _startContinuousSearch();
  }

// في VideoChatScreen - تعديل دالة _startContinuousSearch
  void _startContinuousSearch() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userId;

    if (userId == null) return;

    // بدء الاستماع لإشعارات الجلسات الجديدة
    _listenForSessionNotifications(userId);

    _continuousSearchTimer?.cancel();

    _continuousSearchTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!_shouldContinueSearching || !mounted) {
        timer.cancel();
        return;
      }

      await _performSingleSearchAttempt();
    });

    // تنفيذ أول محاولة فوراً
    _performSingleSearchAttempt();
  }

// دالة جديدة للاستماع لإشعارات الجلسات
  void _listenForSessionNotifications(String userId) {
    _sessionSubscription?.cancel();

    _sessionSubscription = _database
        .child('session_notifications')
        .child(userId)
        .onValue
        .listen((event) async {
      if (event.snapshot.exists && event.snapshot.value != null && _shouldContinueSearching) {
        print('تم تلقي إشعار جلسة جديدة للمستخدم: $userId');

        try {
          final notificationData = event.snapshot.value as Map<dynamic, dynamic>;
          final sessionId = notificationData['sessionId']?.toString();
          final hostId = notificationData['hostId']?.toString();

          if (sessionId != null && hostId != null) {
            // إيقاف البحث
            _stopSearching();

            // إزالة الإشعار
            await _database.child('session_notifications').child(userId).remove();

            // التعامل مع الجلسة كضيف
            await _handleGuestSessionFromNotification(sessionId, hostId, userId);
          }
        } catch (e) {
          print('خطأ في معالجة إشعار الجلسة: $e');
        }
      }
    });
  }

// دالة جديدة للتعامل مع جلسة الضيف من الإشعار
  Future<void> _handleGuestSessionFromNotification(String sessionId, String hostId, String guestId) async {
    try {
      print('التعامل مع جلسة جديدة كضيف - Session: $sessionId, Host: $hostId');

      // الحصول على بيانات المستخدم المضيف
      await _fetchRemoteUserInfo(hostId);

      // إعداد WebRTC كضيف
      final webrtcProvider = context.read<WebRTCProvider>();
      await webrtcProvider.createPeerConnection(sessionId, false);

      // الاستماع لطلبات إعادة إرسال الإجابة
      _listenForAnswerRequests(sessionId);

      // الاستماع لتغييرات الجلسة
      _listenToSessionChanges(sessionId);

      // بدء مراقبة الاتصال
      _startConnectionMonitoring();

      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isWaitingForMatch = false;
          _isInSearchMode = false;
          _showRemoteInfo = true;
        });
      }

      print('تم إعداد الجلسة كضيف بنجاح');
    } catch (e) {
      print('خطأ في إعداد جلسة الضيف: $e');
      // في حالة الفشل، أعد البدء في البحث
      if (mounted) {
        _startContinuousSearch();
      }
    }
  }

// دالة محاولة البحث الواحدة
  Future<void> _performSingleSearchAttempt() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final sessionProvider = context.read<SessionProvider>();

      final userId = authProvider.userId;
      if (userId == null || !_shouldContinueSearching) return;

      // تحديث حالة المستخدم
      final userModel = authProvider.createUserModel();
      await sessionProvider.updateUserStatus(userId, userModel);

      // البحث عن مطابقة
      String? matchedUserId = await sessionProvider.findMatchViaWaitingRoom(
          userId,
          authProvider.filterPreferences
      );

      if (matchedUserId != null && _shouldContinueSearching) {
        // تم العثور على مطابقة! عرض معاينة المستخدم
        _stopSearching();
        await _showUserPreview(matchedUserId);
      }
    } catch (e) {
      print('خطأ في محاولة البحث: $e');
    }
  }

  Future<void> _showUserPreview(String matchedUserId) async {
    try {
      setState(() {
        _showingUserPreview = true;
        _matchedUserId = matchedUserId;
      });

      // الحصول على معلومات المستخدم
      await _fetchRemoteUserInfo(matchedUserId);

      if (!mounted) return;

      // عرض معاينة المستخدم
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => UserPreviewDialog(
          userName: _remoteUserName.isNotEmpty ? _remoteUserName : 'مستخدم',
          userCountry: _remoteUserCountry.isNotEmpty ? _remoteUserCountry : 'غير محدد',
          userGender: _remoteUserGender.isNotEmpty ? _remoteUserGender : 'غير محدد',
          onAccept: () {
            Navigator.of(context).pop();
            _acceptMatch();
          },
          onReject: () {
            Navigator.of(context).pop();
            _rejectMatch();
          },
        ),
      );
    } catch (e) {
      print('خطأ في عرض معاينة المستخدم: $e');
      // في حالة الفشل، ابدأ البحث مرة أخرى
      _startContinuousSearch();
    }
  }

  Future<void> _acceptMatch() async {
    if (_matchedUserId == null) return;

    try {
      final sessionProvider = context.read<SessionProvider>();
      final webrtcProvider = context.read<WebRTCProvider>();
      final authProvider = context.read<AuthProvider>();

      final userId = authProvider.userId!;

      // إنشاء جلسة جديدة
      final session = await sessionProvider.createSession(userId, _matchedUserId!);

      if (session == null) {
        throw Exception('فشل في إنشاء جلسة الدردشة');
      }

      print('تم إنشاء الجلسة: ${session.id}');

      // إنشاء اتصال WebRTC كمضيف
      await webrtcProvider.createPeerConnection(session.id, true);

      // الاستماع لتغييرات الجلسة
      _listenToSessionChanges(session.id);

      // بدء مراقبة الاتصال
      _startConnectionMonitoring();

      setState(() {
        _isConnecting = false;
        _isWaitingForMatch = false;
        _isInSearchMode = false;
        _showRemoteInfo = true;
        _showingUserPreview = false;
        _matchedUserId = null;
      });
    } catch (e) {
      print('خطأ في قبول المطابقة: $e');
      setState(() {
        _errorMessage = 'فشل في بدء المحادثة: $e';
        _showingUserPreview = false;
        _matchedUserId = null;
      });
      _startContinuousSearch();
    }
  }

  Future<void> _rejectMatch() async {
    setState(() {
      _showingUserPreview = false;
      _matchedUserId = null;
      _remoteUserName = "";
      _remoteUserCountry = "";
      _remoteUserGender = "";
    });

    // العودة للبحث عن مستخدم آخر
    _startContinuousSearch();
  }

// دالة التعامل مع المطابقة الموجودة
  Future<void> _handleMatchFound(String matchedUserId, SessionProvider sessionProvider, WebRTCProvider webrtcProvider) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId!;

      print('تم العثور على مستخدم للمطابقة: $matchedUserId');

      // إنشاء جلسة جديدة
      final session = await sessionProvider.createSession(userId, matchedUserId);

      if (session == null) {
        throw Exception('فشل في إنشاء جلسة الدردشة');
      }

      print('تم إنشاء الجلسة: ${session.id}');

      // الحصول على بيانات المستخدم المطابق
      await _fetchRemoteUserInfo(matchedUserId);

      // إنشاء اتصال WebRTC كمضيف
      await webrtcProvider.createPeerConnection(session.id, true);

      // الاستماع لتغييرات الجلسة
      _listenToSessionChanges(session.id);

      // بدء مراقبة الاتصال
      _startConnectionMonitoring();

      setState(() {
        _isConnecting = false;
        _isWaitingForMatch = false;
        _isInSearchMode = false;
        _showRemoteInfo = true;
      });
    } catch (e) {
      print('خطأ في التعامل مع المطابقة: $e');
      // في حالة الفشل، أعد البدء في البحث
      _startContinuousSearch();
    }
  }

// في VideoChatScreen - تعديل دالة _stopSearching
  void _stopSearching() {
    _shouldContinueSearching = false;
    _continuousSearchTimer?.cancel();
    _waitingRoomTimer?.cancel();
    _waitingRoomSubscription?.cancel();
    _sessionSubscription?.cancel();

    // تنظيف إشعارات الجلسات
    final authProvider = context.read<AuthProvider>();
    if (authProvider.userId != null) {
      _database.child('session_notifications').child(authProvider.userId!).remove().catchError((e) {
        print('خطأ في تنظيف إشعارات الجلسة: $e');
      });
    }
  }

  // وظيفة جديدة للحصول على معلومات المستخدم المطابق
  Future<void> _fetchRemoteUserInfo(String userId) async {
    try {
      final snapshot = await _database.child('users').child(userId).get();

      if (snapshot.exists && snapshot.value != null) {
        try {
          final data = snapshot.value as Map<dynamic, dynamic>;

          // تحويل آمن من Map<dynamic, dynamic> إلى Map<String, dynamic>
          final userData = <String, dynamic>{};
          data.forEach((key, value) {
            userData[key.toString()] = value;
          });

          setState(() {
            _remoteUserName = userData['name'] ?? 'مستخدم';
            _remoteUserCountry = userData['country'] ?? 'غير محدد';
            _remoteUserGender = userData['gender'] ?? 'غير محدد';
          });
        } catch (e) {
          print('خطأ في تحويل بيانات المستخدم: $e');
          setState(() {
            _remoteUserName = 'مستخدم';
            _remoteUserCountry = 'غير محدد';
            _remoteUserGender = 'غير محدد';
          });
        }
      }
    } catch (e) {
      print('خطأ في جلب بيانات المستخدم: $e');
    }
  }

  void _setupWaitingRoomListener(String userId) {
    // إلغاء الاستماع السابق إن وجد
    _waitingRoomSubscription?.cancel();
    _sessionSubscription?.cancel();

    print('إعداد مراقبة غرفة الانتظار للمستخدم: $userId');

    // مراقبة الجلسات التي يكون فيها المستخدم ضيفًا
    _sessionSubscription = _database
        .child('sessions')
        .orderByChild('guestId')
        .equalTo(userId)
        .onChildAdded
        .listen((event) async {
      print('تم اكتشاف جلسة جديدة للضيف $userId');

      if (event.snapshot.exists && event.snapshot.value != null && _shouldContinueSearching) {
        print('معالجة جلسة جديدة للمستخدم $userId كضيف');

        _stopSearching();

        try {
          await _database.child('waiting_room').child(userId).remove();
          print('تم إزالة الضيف من غرفة الانتظار');
        } catch (e) {
          print('خطأ في إزالة الضيف من غرفة الانتظار: $e');
        }

        await _handleGuestSession(event);
      }
    });

    // مراقبة الجلسات التي يكون فيها المستخدم مضيفًا
    _database
        .child('sessions')
        .orderByChild('hostId')
        .equalTo(userId)
        .onChildAdded
        .listen((event) async {
      print('تم اكتشاف جلسة جديدة للمضيف $userId');

      if (event.snapshot.exists && event.snapshot.value != null && _shouldContinueSearching) {
        print('معالجة جلسة جديدة للمستخدم $userId كمضيف من الاستماع');

        _stopSearching();

        try {
          await _database.child('waiting_room').child(userId).remove();
          print('تم إزالة المضيف من غرفة الانتظار');
        } catch (e) {
          print('خطأ في إزالة المضيف من غرفة الانتظار: $e');
        }

        final sessionId = event.snapshot.key!;
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        final sessionData = <String, dynamic>{};
        data.forEach((key, value) {
          sessionData[key.toString()] = value;
        });

        await _fetchRemoteUserInfo(sessionData['guestId'] ?? '');

        if (mounted) {
          setState(() {
            _isConnecting = false;
            _isWaitingForMatch = false;
            _isInSearchMode = false;
            _showRemoteInfo = true;
          });
        }
      }
    });

    // إضافة مراقبة الإشعارات المرتبطة بالجلسات
    _listenForSessionNotifications(userId);
  }

  Future<void> _handleGuestSession(DatabaseEvent event) async {
    try {
      final sessionId = event.snapshot.key!;
      final data = event.snapshot.value as Map<dynamic, dynamic>;

      print('معالجة جلسة الضيف: $sessionId');

      // تحويل آمن من Map<dynamic, dynamic> إلى Map<String, dynamic>
      final sessionData = <String, dynamic>{};
      data.forEach((key, value) {
        sessionData[key.toString()] = value;
      });

      final session = SessionModel(
        id: sessionId,
        hostId: sessionData['hostId'] ?? '',
        guestId: sessionData['guestId'] ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(sessionData['createdAt'] ?? 0),
        isActive: sessionData['isActive'] ?? true,
      );

      print('جلسة الضيف - المضيف: ${session.hostId}, الضيف: ${session.guestId}');

      // الحصول على بيانات المستخدم المضيف
      await _fetchRemoteUserInfo(session.hostId);

      // إعداد WebRTC كضيف
      final webrtcProvider = context.read<WebRTCProvider>();
      print('إنشاء اتصال WebRTC للضيف...');
      await webrtcProvider.createPeerConnection(session.id, false);

      // الاستماع لطلبات إعادة إرسال الإجابة
      _listenForAnswerRequests(session.id);

      // الاستماع لتغييرات الجلسة
      _listenToSessionChanges(session.id);

      // بدء مراقبة الاتصال
      _startConnectionMonitoring();

      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isWaitingForMatch = false;
          _isInSearchMode = false;
          _showRemoteInfo = true;
        });

        print('تم تحديث حالة واجهة المستخدم للضيف');
      }
    } catch (e) {
      print('خطأ في معالجة جلسة الضيف: $e');

      // في حالة الفشل، أعد بدء البحث
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل في الاتصال، جاري المحاولة مرة أخرى...';
        });

        // إعادة بدء البحث بعد تأخير قصير
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            _connectToRandomUser();
          }
        });
      }
    }
  }

  Future<void> _handleGuestSessionFromSnapshot(DataSnapshot snapshot) async {
    try {
      final sessionId = snapshot.key!;
      final data = snapshot.value as Map<dynamic, dynamic>;

      print('معالجة جلسة الضيف: $sessionId');

      // تحويل آمن من Map<dynamic, dynamic> إلى Map<String, dynamic>
      final sessionData = <String, dynamic>{};
      data.forEach((key, value) {
        sessionData[key.toString()] = value;
      });

      final session = SessionModel(
        id: sessionId,
        hostId: sessionData['hostId'] ?? '',
        guestId: sessionData['guestId'] ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(sessionData['createdAt'] ?? 0),
        isActive: sessionData['isActive'] ?? true,
      );

      print('جلسة الضيف - المضيف: ${session.hostId}, الضيف: ${session.guestId}');

      // الحصول على بيانات المستخدم المضيف
      await _fetchRemoteUserInfo(session.hostId);

      // إعداد WebRTC كضيف
      final webrtcProvider = context.read<WebRTCProvider>();
      print('إنشاء اتصال WebRTC للضيف...');
      await webrtcProvider.createPeerConnection(session.id, false);

      // الاستماع لطلبات إعادة إرسال الإجابة
      _listenForAnswerRequests(session.id);

      // الاستماع لتغييرات الجلسة
      _listenToSessionChanges(session.id);

      // بدء مراقبة الاتصال
      _startConnectionMonitoring();

      if (mounted) {
        setState(() {
          _isConnecting = false;
          _isWaitingForMatch = false;
          _isInSearchMode = false;
          _showRemoteInfo = true;
        });

        print('تم تحديث حالة واجهة المستخدم للضيف');
      }
    } catch (e) {
      print('خطأ في معالجة جلسة الضيف: $e');

      // في حالة الفشل، أعد بدء البحث
      if (mounted) {
        setState(() {
          _errorMessage = 'فشل في الاتصال، جاري المحاولة مرة أخرى...';
        });

        // إعادة بدء البحث بعد تأخير قصير
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            _connectToRandomUser();
          }
        });
      }
    }
  }

  // الاستماع لطلبات إعادة إرسال الإجابة
  void _listenForAnswerRequests(String sessionId) {
    _database
        .child('sessions')
        .child(sessionId)
        .child('requestAnswer')
        .onValue
        .listen((event) async {
          if (event.snapshot.exists && event.snapshot.value != null) {
            print('تم استلام طلب إجابة جديدة');

            try {
              // الحصول على العرض وإعادة معالجته
              final offerSnapshot =
                  await _database
                      .child('sessions')
                      .child(sessionId)
                      .child('offer')
                      .get();

              if (offerSnapshot.exists && offerSnapshot.value != null) {
                final offerData = Map<String, dynamic>.from(
                  offerSnapshot.value as Map,
                );

                // إعادة إنشاء الإجابة من خلال WebRTCProvider
                final webrtcProvider = context.read<WebRTCProvider>();
                final answerMap = await webrtcProvider.handleOffer(offerData);

                // إرسال الإجابة الجديدة
                await _database
                    .child('sessions')
                    .child(sessionId)
                    .child('answer')
                    .set(answerMap);
                print('تم إرسال إجابة جديدة استجابة للطلب');
              }
            } catch (e) {
              print('خطأ في معالجة طلب الإجابة: $e');
            }
          }
        });
  }

// استبدل دالة _setupRetryTimer بهذه النسخة المحسنة
  void _setupRetryTimer(String userId) {
    // إلغاء المؤقت السابق إن وجد
    _waitingRoomTimer?.cancel();

    // إعداد مؤقت لإعادة المحاولة بعد 30 ثانية (بدلاً من 15)
    _waitingRoomTimer = Timer(const Duration(seconds: 30), () async {
      if (_isWaitingForMatch && mounted && !_isConnecting) {
        print('لم يتم العثور على مطابقة بعد 30 ثانية، إعادة المحاولة');

        try {
          // تنظيف غرفة الانتظار
          await _database.child('waiting_room').child(userId).remove();

          // إلغاء الاشتراكات الحالية
          _waitingRoomSubscription?.cancel();
          _sessionSubscription?.cancel();

          // إعادة المحاولة مع تأخير قصير
          await Future.delayed(const Duration(milliseconds: 1000));

          if (mounted && !_isConnecting) {
            setState(() {
              _isWaitingForMatch = false;
            });
            _connectToRandomUser();
          }
        } catch (e) {
          print('خطأ في إعادة المحاولة: $e');
          if (mounted) {
            setState(() {
              _errorMessage = 'فشل في العثور على مستخدم، يرجى المحاولة مرة أخرى';
              _isWaitingForMatch = false;
              _isConnecting = false;
            });
          }
        }
      }
    });
  }

  void _listenToSessionChanges(String sessionId) {
    final sessionProvider = context.read<SessionProvider>();

    // مراقبة تغييرات الجلسة العامة
    sessionProvider.listenToSessionChanges(
      sessionId,
          (updatedSession) {
        print('تم تحديث الجلسة: ${updatedSession.id}, نشطة: ${updatedSession.isActive}');

        if (!updatedSession.isActive && mounted) {
          _handleCallEnded('تم إنهاء المكالمة من قبل المستخدم الآخر');
        }
      },
    );

    // مراقبة إشعارات إنهاء المكالمة المباشرة
    _callEndSubscription = _database
        .child('sessions')
        .child(sessionId)
        .child('callEnded')
        .onValue
        .listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null && mounted) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final endedBy = data['endedBy']?.toString() ?? '';
        final reason = data['reason']?.toString() ?? 'unknown';

        final authProvider = context.read<AuthProvider>();
        final currentUserId = authProvider.userId ?? '';

        // تحقق أن المكالمة لم تنته من قبل المستخدم الحالي
        if (endedBy != currentUserId) {
          print('تم استلام إشعار إنهاء المكالمة من: $endedBy');
          _handleCallEnded('انتهت المكالمة');
        }
      }
    });
  }

// دالة جديدة للتعامل مع إنهاء المكالمة
  Future<void> _handleCallEnded(String message) async {
    if (!mounted) return;

    try {
      // إيقاف البحث والاتصالات الحالية
      _stopSearching();

      // تنظيف WebRTC فوراً
      final webrtcProvider = context.read<WebRTCProvider>();
      await webrtcProvider.dispose();

      // إظهار رسالة للمستخدم
      setState(() {
        _errorMessage = message;
        _showRemoteInfo = false;
      });

      // انتظار ثانيتين ثم بدء البحث الجديد تلقائياً
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _errorMessage = null;
        });

        // إعادة تهيئة WebRTC وبدء البحث الجديد
        await webrtcProvider.reinitialize();
        await webrtcProvider.getUserMedia();
        _connectToRandomUser();
      }
    } catch (e) {
      print('خطأ في التعامل مع إنهاء المكالمة: $e');
    }
  }

  Future<void> _handleNextUser() async {
    try {
      // عرض إعلان فاصل قبل البحث عن مستخدم جديد (احتمالية 50%)
      final adService = Provider.of<AdService>(context, listen: false);
      if (Random().nextDouble() < 0.5) {
        await adService.showSmartInterstitialAd();
      }

      // إيقاف البحث الحالي
      _stopSearching();

      // إنهاء الجلسة الحالية في Firebase
      final sessionProvider = context.read<SessionProvider>();
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId != null) {
        await sessionProvider.endSession(userId);
      }

      // تنظيف WebRTC بالكامل
      final webrtcProvider = context.read<WebRTCProvider>();
      await webrtcProvider.dispose();

      // إعادة تهيئة WebRTC
      await webrtcProvider.reinitialize();
      await webrtcProvider.getUserMedia();

      // إلغاء اشتراكات المكالمة السابقة
      _callEndSubscription?.cancel();

      // إعادة تعيين الحالة
      setState(() {
        _showRemoteInfo = false;
        _remoteUserName = "";
        _remoteUserCountry = "";
        _remoteUserGender = "";
      });

      // بدء البحث الجديد
      _connectToRandomUser();
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في الانتقال إلى المستخدم التالي: $e';
        _isConnecting = false;
      });
    }
  }

  Future<void> _handleEndCall() async {
    try {
      // إيقاف البحث والاتصالات
      _stopSearching();

      // تنظيف الجلسة من Firebase أولاً
      final sessionProvider = context.read<SessionProvider>();
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId != null) {
        await sessionProvider.endSession(userId);
      }

      // عرض إعلان عند إنهاء المكالمة
      final adService = Provider.of<AdService>(context, listen: false);
      await adService.showSessionEndAd();

      // تنظيف WebRTC
      final webrtcProvider = context.read<WebRTCProvider>();
      await webrtcProvider.dispose();

      // إلغاء جميع الاشتراكات
      _callEndSubscription?.cancel();
      _sessionSubscription?.cancel();
      _waitingRoomSubscription?.cancel();

      // العودة إلى الشاشة السابقة
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('خطأ في إنهاء المكالمة: $e');
      // حتى لو حدث خطأ، أغلق الشاشة
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _tryReconnect() async {
    if (_reconnectAttempts >= _maxReconnectAttempts || _isReconnecting) return;

    setState(() {
      _isReconnecting = true;
      _reconnectAttempts++;
    });

    try {
      // الحصول على معرف الجلسة الحالية
      final sessionProvider = context.read<SessionProvider>();
      final webrtcProvider = context.read<WebRTCProvider>();
      final authProvider = context.read<AuthProvider>();

      if (sessionProvider.currentSession != null) {
        final session = sessionProvider.currentSession!;
        final userId = authProvider.userId;

        // تنظيف اتصال WebRTC الحالي
        await webrtcProvider.dispose();
        await webrtcProvider.initRenderers();
        await webrtcProvider.getUserMedia();

        // إعادة إنشاء الاتصال
        final isHost = session.hostId == userId;
        await webrtcProvider.createPeerConnection(session.id, isHost);

        setState(() {
          _isReconnecting = false;
          _errorMessage = null;
        });
      } else {
        // إعادة المحاولة من البداية
        await _cleanup();
        _connectToRandomUser();
      }
    } catch (e) {
      print('فشلت محاولة إعادة الاتصال: $e');
      setState(() {
        _isReconnecting = false;
        _errorMessage = 'فشلت محاولة إعادة الاتصال، يرجى المحاولة مرة أخرى';
      });
    }
  }

// استبدل دالة _cleanup الحالية بهذه النسخة
  Future<void> _cleanup() async {
    try {
      // إيقاف جميع المؤقتات والاشتراكات
      _waitingRoomTimer?.cancel();
      _connectionCheckTimer?.cancel();
      _waitingRoomSubscription?.cancel();
      _sessionSubscription?.cancel();

      final sessionProvider = context.read<SessionProvider>();
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId != null) {
        // إزالة من غرفة الانتظار أولاً
        try {
          await _database.child('waiting_room').child(userId).remove();
        } catch (e) {
          print('خطأ في إزالة المستخدم من غرفة الانتظار: $e');
        }

        // إنهاء الجلسة الحالية
        try {
          await sessionProvider.endSession(userId);
        } catch (e) {
          print('خطأ في إنهاء الجلسة: $e');
        }
      }

      // إعادة تعيين الحالة المحلية
      setState(() {
        _isWaitingForMatch = false;
        _isConnecting = false;
        _errorMessage = null;
        _connectionState = "غير متصل";
        _iceConnectionState = "غير متصل";
      });

    } catch (e) {
      print('خطأ في تنظيف الموارد: $e');
    }
  }

  Future<void> _onPermissionGranted() async {
    setState(() {
      _isPermissionGranted = true;
    });

    try {
      // حفظ حالة الأذونات
      await PermissionService.savePermissionStatus(true);

      // تهيئة الكاميرا والميكروفون
      await context.read<WebRTCProvider>().getUserMedia();

      // الاتصال بمستخدم عشوائي
      _connectToRandomUser();
    } catch (e) {
      setState(() {
        _errorMessage = 'فشل في الوصول إلى الكاميرا أو الميكروفون: $e';
      });
      print('خطأ في الأذونات: $e');
    }
  }

  // توجيه لمعرفة المزيد عن المستخدم المقابل
  void _toggleUserInfo() {
    setState(() {
      _showRemoteInfo = !_showRemoteInfo;
    });
  }

  // توجيه لإظهار/إخفاء شريط فلاتر الفيديو
  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  // وأضف هذه الدالة في الكلاس
  void _showReportDialog() {
    final authProvider = context.read<AuthProvider>();
    final sessionProvider = context.read<SessionProvider>();

    if (sessionProvider.currentSession == null || authProvider.userId == null) return;

    final session = sessionProvider.currentSession!;
    final currentUserId = authProvider.userId!;

    // تحديد معرف المستخدم الذي سيتم الإبلاغ عنه
    final reportedUserId = session.hostId == currentUserId
        ? session.guestId
        : session.hostId;

    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        reporterId: currentUserId,
        reportedUserId: reportedUserId,
        reportedUserName: _remoteUserName.isEmpty ? 'المستخدم' : _remoteUserName,
        sessionId: session.id,
      ),
    ).then((wasReported) {
      if (wasReported == true) {
        // إظهار رسالة تأكيد بعد الإبلاغ
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال البلاغ بنجاح، شكرا لمساعدتنا في الحفاظ على مجتمع آمن'),
            backgroundColor: Colors.green,
          ),
        );

        // إنهاء المحادثة تلقائياً بعد الإبلاغ
        _handleEndCall();
      }
    });
  }

  void _startSessionTimer() {
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _sessionDuration++;
      });

      // عرض الإعلانات في أوقات محددة من الجلسة
      _checkTimeBasedAds();
    });
  }

  void _checkTimeBasedAds() {
    // عرض إعلان كل 4 دقائق من المحادثة المستمرة
    final adService = Provider.of<AdService>(context, listen: false);

    // إذا كانت المحادثة مستمرة لفترة طويلة، عرض إعلان فاصل كل 4 دقائق
    if (_sessionDuration > 0 && _sessionDuration % 240 == 0) { // 4 دقائق = 240 ثانية
      adService.showSmartInterstitialAd();
    }

    // إخفاء وإظهار الإعلان الشريطي بالتناوب لتحسين تجربة المستخدم
    if (_sessionDuration > 0 && _sessionDuration % 120 == 0) { // كل دقيقتين
      setState(() {
        _showBottomBanner = !_showBottomBanner;
      });
    }
  }

  void _ensureSearchContinues() {
    // إذا لم يكن هناك جلسة نشطة ولا يوجد بحث جاري، ابدأ البحث
    final sessionProvider = context.read<SessionProvider>();

    if (!sessionProvider.isInActiveSession &&
        !_isConnecting &&
        !_isWaitingForMatch &&
        _isPermissionGranted) {

      print('الحالة غير متوقعة، إعادة تشغيل البحث تلقائياً');

      // تأخير قصير ثم بدء البحث
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted &&
            !sessionProvider.isInActiveSession &&
            !_isConnecting &&
            !_isWaitingForMatch) {
          _connectToRandomUser();
        }
      });
    }
  }

// تعديل دالة dispose في video_chat_screen.dart
  @override
  void dispose() {
    _stopSearching();
    _cleanup();
    _waitingRoomTimer?.cancel();
    _connectionCheckTimer?.cancel();
    _continuousSearchTimer?.cancel();
    _waitingRoomSubscription?.cancel();
    _sessionSubscription?.cancel();
    _callEndSubscription?.cancel(); // إضافة هذا السطر
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionProvider = context.watch<SessionProvider>();
    final webrtcProvider = context.watch<WebRTCProvider>();
    final authProvider = context.watch<AuthProvider>();
    // استخدم نظام الترجمة
    final t = AppLocalizations.of(context)!;

    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (!_isPermissionGranted) {
      return PermissionHandler(onPermissionGranted: _onPermissionGranted);
    }

    final isInSession = sessionProvider.isInActiveSession;
    final isSearching = sessionProvider.isSearching || _isConnecting;
    final isConnected = webrtcProvider.isConnectionEstablished;
    // تبسيط منطق العرض - إما في جلسة أو في وضع البحث
    final isInSearchMode = _isInSearchMode || _isWaitingForMatch || _isConnecting;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // فيديو بعيد (الشخص الآخر) أو شاشة البحث
            if (isInSession && isConnected)
              Positioned.fill(
                child: videoRender.VideoRenderer(
                  renderer: webrtcProvider.remoteRenderer,
                  isLocal: false,
                ),
              )
// في دالة build، استبدل الجزء الخاص بشاشة البحث بهذا:
            else
            // شاشة البحث المحسنة
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.9),
                        Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                        Colors.black,
                      ],
                    ),
                  ),
                  child: Center(
                    child: _isReconnecting
                        ? Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                            color: Colors.blue,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'جاري إعادة الاتصال...',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '(${_reconnectAttempts}/${_maxReconnectAttempts})',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                        : SearchAnimationWidget(
                      usersCount: sessionProvider.usersInWaitingRoom,
                      hasActiveFilters: authProvider.filterPreferences.filterByGender ||
                          authProvider.filterPreferences.filterByCountry,
                    ),
                  ),
                ),
              ),

            // فيديو محلي (أنت)
            Positioned(
              right: 16,
              top: isInSession ? 80 : 16,
              width: 120,
              height: 180,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Stack(
                  children: [
                    videoRender.VideoRenderer(
                      renderer: webrtcProvider.localRenderer,
                      isLocal: true,
                    ),
                    // أزرار تبديل الكاميرا والفلاتر
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 36,
                        color: Colors.black.withOpacity(0.6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              icon: Icon(
                                webrtcProvider.isFilterApplied
                                    ? Icons.filter_alt
                                    : Icons.filter_alt_outlined,
                                color:
                                webrtcProvider.isFilterApplied
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _toggleFilters,
                              tooltip: t.toggleFilters,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.flip_camera_ios,
                                color: Colors.white,
                                size: 18,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: webrtcProvider.switchCamera,
                              tooltip: t.switchCamera,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // معلومات المستخدم المقابل
            if (isInSession && isConnected && _showRemoteInfo)
              Positioned(
                top: 16,
                left: 16,
                child: UserInfoCard(
                  name: _remoteUserName,
                  country: _remoteUserCountry,
                  gender: _remoteUserGender,
                  onClose: _toggleUserInfo,
                ),
              ),

            // زر إظهار معلومات المستخدم
            if (isInSession && isConnected && !_showRemoteInfo)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.info_outline, color: Colors.white),
                    onPressed: _toggleUserInfo,
                    tooltip: t.userInfo,
                  ),
                ),
              ),

            if (isInSession && isConnected && _showRemoteInfo)
              Positioned(
                top: 16,
                right: 150, // تعديل الموضع حسب الحاجة
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.report_problem, color: Colors.white),
                    tooltip: t.reportUser,
                    onPressed: _currentSession != null ? () => _showReportDialog() : null,
                  ),
                ),
              ),

            // معلومات حالة الاتصال (للتشخيص)
            if (isInSession)
              Positioned(
                left: 16,
                bottom: isInSession ? 120 : 80,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.connectionStatus(_connectionState),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        t.iceConnectionStatus(_iceConnectionState),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // فلاتر الفيديو
            if (_showFilters)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: const VideoFilters(),
              ),

            // أزرار التحكم
            Positioned(
              left: 0,
              right: 0,
              bottom: 45,
              child: ActionButtons(
                isMicEnabled: webrtcProvider.isMicEnabled,
                isCameraEnabled: webrtcProvider.isCameraEnabled,
                isConnected: isInSession,
                isLoading: isSearching || _isWaitingForMatch || _isReconnecting,
                onToggleMic: webrtcProvider.toggleMic,
                onToggleCamera: webrtcProvider.toggleCamera,
                onSwitchCamera: webrtcProvider.switchCamera,
                onNextUser: _handleNextUser,
                onEndCall: _handleEndCall,
              ),
            ),

            // أضف هذا في Stack في أسفل الشاشة (بعد أزرار التحكم)
            if (isInSearchMode && !_showingUserPreview)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: ElevatedButton(
                    onPressed: _handleEndCall,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.close, size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'إلغاء البحث',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 2000.ms, duration: 800.ms)
                      .slideY(begin: 0.5, end: 0),
                ),
              ),

            if (_showBottomBanner)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0, // ضبط موضع الإعلان فوق أزرار التحكم
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Provider.of<AdService>(context, listen: false).getBannerAdWidget(),
                ),
              ),

            // رسالة الخطأ
            if (_errorMessage != null)
              Positioned(
                left: 0,
                right: 0,
                top: 100,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isInSession && !isConnected)
                            ElevatedButton(
                              onPressed: _tryReconnect,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: Text(t.reconnect),
                            ),


                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _errorMessage = null;
                              });
                              _handleNextUser();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                            ),
                            child: Text(t.nextUser),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}