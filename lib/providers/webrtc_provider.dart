import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as flutter_webrtc;
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';

class WebRTCProvider with ChangeNotifier {
  final _database = FirebaseDatabase.instance.ref();

  // متغيرات WebRTC
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer? _localRenderer;
  RTCVideoRenderer? _remoteRenderer;

  bool _isMicEnabled = true;
  bool _isCameraEnabled = true;
  bool _isFrontCamera = true;
  bool _isConnectionEstablished = false;
// إضافة متغيرات جديدة لدعم الفلاتر
  String _activeFilter = 'none';
  bool _isFilterApplied = false;

// Getters
  String get activeFilter => _activeFilter;
  bool get isFilterApplied => _isFilterApplied;
  MediaStream? get localStream => _localStream;
  RTCVideoRenderer get localRenderer => _localRenderer ?? RTCVideoRenderer();
  RTCVideoRenderer get remoteRenderer => _remoteRenderer ?? RTCVideoRenderer();
  bool get isMicEnabled => _isMicEnabled;
  bool get isCameraEnabled => _isCameraEnabled;
  bool get isFrontCamera => _isFrontCamera;
  bool get isConnectionEstablished => _isConnectionEstablished;

  WebRTCProvider() {
    // إنشاء الكائنات عند بدء التشغيل
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();
  }

  // تهيئة WebRTC
  Future<void> initRenderers() async {
    try {
      // إنشاء محركات عرض جديدة إذا لم تكن موجودة أو تم التخلص منها
      _localRenderer ??= RTCVideoRenderer();
      _remoteRenderer ??= RTCVideoRenderer();

      // تهيئة محركات العرض
      await _localRenderer!.initialize();
      await _remoteRenderer!.initialize();

      notifyListeners();
      print('تم تهيئة محركات العرض بنجاح');
    } catch (e) {
      print('خطأ في تهيئة محركات العرض: $e');
      rethrow;
    }
  }

  // الحصول على الوسائط المحلية
  Future<void> getUserMedia() async {
    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': {
        'facingMode': _isFrontCamera ? 'user' : 'environment',
        'mandatory': {
          'minWidth': '640',
          'minHeight': '480',
          'minFrameRate': '24',
        },
        'optional': [],
      }
    };

    try {
      print('طلب الوصول إلى الكاميرا والميكروفون...');

      // التحقق من أن محركات العرض جاهزة
      if (_localRenderer == null || _remoteRenderer == null) {
        await initRenderers();
      }

      _localStream = await navigator.mediaDevices.getUserMedia(constraints);

      // تعيين الـ Stream للعارض
      if (_localRenderer != null) {
        _localRenderer!.srcObject = _localStream;
      }

      print('تم الحصول على الوسائط المحلية: ${_localStream?.id}');
      print('عدد مسارات الفيديو: ${_localStream?.getVideoTracks().length}');
      print('عدد مسارات الصوت: ${_localStream?.getAudioTracks().length}');

      notifyListeners();
    } catch (e) {
      print('خطأ في الحصول على الوسائط: $e');
      rethrow;
    }
  }

  // إنشاء اتصال P2P
  Future<void> createPeerConnection(String sessionId, bool isHost) async {
    final Map<String, dynamic> config = {
      'iceServers': [
        {'urls': ['stun:stun1.l.google.com:19302']},
        {'urls': ['stun:stun2.l.google.com:19302']},
        {
          'urls': [
            'turn:numb.viagenie.ca',
            'turn:numb.viagenie.ca:3478?transport=tcp'
          ],
          'username': 'webrtc@live.com',
          'credential': 'muazkh'
        },
        {
          'urls': [
            'turn:turn.anyfirewall.com:443?transport=tcp'
          ],
          'username': 'webrtc',
          'credential': 'webrtc'
        }
      ],
      'iceCandidatePoolSize': 10,
      'sdpSemantics': 'unified-plan',
      'iceTransportPolicy': 'all',
      'bundlePolicy': 'max-bundle',
      'rtcpMuxPolicy': 'require'
    };

    final Map<String, dynamic> offerSdpConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': [],
    };

    try {
      print('إنشاء اتصال نظير لنظير...');
      print('أنا ${isHost ? "المضيف" : "الضيف"} في هذه الجلسة');

      _peerConnection = await flutter_webrtc.createPeerConnection(config, offerSdpConstraints);

      _setupPeerConnectionListeners(sessionId, isHost);

      if (_localStream != null) {
        print('إضافة المسارات المحلية إلى الاتصال P2P');
        _localStream!.getTracks().forEach((track) {
          _peerConnection!.addTrack(track, _localStream!);
          print('تمت إضافة المسار: ${track.kind}');
        });
      } else {
        print('تحذير: تدفق الوسائط المحلية غير متاح عند إنشاء الاتصال');
      }

      if (isHost) {
        print('أنا المضيف، إنشاء عرض SDP...');
        try {
          final RTCSessionDescription offer =
          await _peerConnection!.createOffer(offerSdpConstraints);

          print('تم إنشاء العرض بنجاح، تعيين العرض كوصف محلي');
          await _peerConnection!.setLocalDescription(offer);

          print('إرسال العرض إلى Firebase');
          await _database
              .child('sessions')
              .child(sessionId)
              .child('offer')
              .set(offer.toMap());

          await _database
              .child('sessions')
              .child(sessionId)
              .child('lastOffer')
              .set({
            'sdp': offer.sdp,
            'type': offer.type,
            'timestamp': DateTime.now().millisecondsSinceEpoch
          });

          print('تم إرسال العرض بنجاح');
        } catch (e) {
          print('خطأ أثناء إنشاء العرض: $e');
          rethrow;
        }
      } else {
        print('أنا الضيف، البحث عن العرض الموجود...');
        await Future.delayed(Duration(milliseconds: 500));

        try {
          final offerSnapshot = await _database
              .child('sessions')
              .child(sessionId)
              .child('offer')
              .get();

          if (offerSnapshot.exists && offerSnapshot.value != null) {
            print('تم العثور على عرض موجود، معالجته...');
            final offerData = Map<String, dynamic>.from(offerSnapshot.value as Map);
            await _processIncomingOffer(offerData, sessionId);
          } else {
            print('لا يوجد عرض موجود، انتظار وصوله...');
          }
        } catch (e) {
          print('خطأ في البحث عن العرض للضيف: $e');
        }
      }

      _listenForRemoteSdp(sessionId, isHost);
      _listenForRemoteIceCandidates(sessionId, isHost);
    } catch (e) {
      print('خطأ في إنشاء اتصال النظير: $e');
      rethrow;
    }
  }

  Future<void> _processIncomingOffer(Map<String, dynamic> offerData, String sessionId) async {
    try {
      print('معالجة العرض الوارد للضيف...');

      final RTCSessionDescription offer = RTCSessionDescription(
        offerData['sdp'],
        offerData['type'],
      );

      print('تعيين العرض كوصف بعيد للضيف');
      await _peerConnection!.setRemoteDescription(offer);

      print('إنشاء إجابة من الضيف');
      final RTCSessionDescription answer = await _peerConnection!.createAnswer();

      print('تعيين الإجابة كوصف محلي للضيف');
      await _peerConnection!.setLocalDescription(answer);

      print('إرسال الإجابة إلى المضيف');
      await _database
          .child('sessions')
          .child(sessionId)
          .child('answer')
          .set(answer.toMap());

      print('تم إرسال الإجابة بنجاح من الضيف');
    } catch (e) {
      print('خطأ في معالجة العرض للضيف: $e');
      rethrow;
    }
  }

  void _setupPeerConnectionListeners(String sessionId, bool isHost) {
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      _sendIceCandidate(sessionId, isHost, candidate);
    };

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      print('استلام مسار عن بعد: ${event.track.kind}');
      if (event.streams.isNotEmpty) {
        print('تعيين تدفق البعيد: ${event.streams[0].id}');
        _remoteRenderer?.srcObject = event.streams[0];

        _isConnectionEstablished = true;
        notifyListeners();
      }
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      print('حالة اتصال ICE: $state');

      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        print('تم إنشاء اتصال ICE بنجاح!');
        _isConnectionEstablished = true;
        notifyListeners();
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        print('فشل اتصال ICE - محاولة إعادة الاتصال');

        // محاولة إعادة تشغيل الاتصال
        Future.delayed(Duration(seconds: 2), () {
          if (!_isConnectionEstablished) {
            _restartIceConnection();
          }
        });
      }
    };

    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      print('حالة اتصال ICE: $state');

      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        print('✅ تم إنشاء اتصال ICE بنجاح!');
        _isConnectionEstablished = true;
        notifyListeners();
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        print('❌ فشل اتصال ICE أو انقطع');
        _isConnectionEstablished = false;
        notifyListeners();

        // إذا كان المضيف، حاول إعادة طلب الإجابة
        if (isHost) {
          print('محاولة إعادة طلب الإجابة من المضيف...');
          _requestAnswer(sessionId);
        } else {
          // إذا كان الضيف، حاول إعادة إرسال الإجابة
          print('محاولة إعادة إرسال الإجابة من الضيف...');
          _resendAnswer(sessionId);
        }
      }
    };

    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      print('حالة اتصال النظير: $state');

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        print('✅ اتصال النظير ناجح!');
        _isConnectionEstablished = true;
        notifyListeners();
      }
    };

    _peerConnection!.onIceGatheringState = (RTCIceGatheringState state) {
      print('حالة تجميع ICE: $state');
    };

    _peerConnection!.onSignalingState = (RTCSignalingState state) {
      print('حالة الإشارة: $state');
    };

    _peerConnection!.onAddStream = (MediaStream stream) {
      print('إضافة تدفق: ${stream.id}');
      print('عدد مسارات الفيديو: ${stream.getVideoTracks().length}');
      print('عدد مسارات الصوت: ${stream.getAudioTracks().length}');

      _remoteRenderer?.srcObject = stream;
      _isConnectionEstablished = true;
      notifyListeners();

      print('✅ تم تعيين تدفق الفيديو البعيد بنجاح!');
    };
  }

  // دالة جديدة لإعادة تشغيل اتصال ICE
  Future<void> _restartIceConnection() async {
    try {
      print('إعادة تشغيل اتصال ICE...');
      await _peerConnection?.restartIce();
    } catch (e) {
      print('خطأ في إعادة تشغيل ICE: $e');
    }
  }

  // معالجة العرض (للضيف)
  Future<Map<String, dynamic>> handleOffer(Map<String, dynamic> offer) async {
    try {
      print('معالجة العرض من المضيف...');
      final RTCSessionDescription description =
      RTCSessionDescription(offer['sdp'], offer['type']);

      print('تعيين العرض كوصف بعيد');
      await _peerConnection!.setRemoteDescription(description);

      print('إنشاء إجابة...');
      final RTCSessionDescription answer = await _peerConnection!.createAnswer();

      print('تعيين الإجابة كوصف محلي');
      await _peerConnection!.setLocalDescription(answer);

      print('تم إعداد الإجابة: ${answer.type}');
      return answer.toMap();
    } catch (e) {
      print('خطأ في معالجة العرض: $e');
      rethrow;
    }
  }

  // الاستماع لـ SDP البعيد
  void _listenForRemoteSdp(String sessionId, bool isHost) {
    final String remoteSdpPath = isHost ? 'answer' : 'offer';

    print('بدء الاستماع لـ SDP البعيد على المسار: $remoteSdpPath');

    _database
        .child('sessions')
        .child(sessionId)
        .child(remoteSdpPath)
        .onValue
        .listen((event) async {
      if (event.snapshot.exists && event.snapshot.value != null) {
        print('تم استلام SDP البعيد! المسار: $remoteSdpPath');

        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

          final RTCSessionDescription description =
          RTCSessionDescription(data['sdp'], data['type']);

          // التحقق من حالة الإشارة قبل تعيين الوصف البعيد
          // استخدام await هنا لأن getSignalingState تعيد Future
          RTCSignalingState? signalingState = await _peerConnection!.getSignalingState();
          print('حالة الإشارة الحالية: $signalingState');

          if (isHost && signalingState != RTCSignalingState.RTCSignalingStateHaveRemoteOffer) {
            print('تعيين الإجابة البعيدة للمضيف');
            await _peerConnection!.setRemoteDescription(description);
          } else if (!isHost && signalingState != RTCSignalingState.RTCSignalingStateHaveLocalOffer) {
            print('تعيين العرض البعيد للضيف');

            await _peerConnection!.setRemoteDescription(description);

            // إنشاء وإرسال الإجابة
            print('إنشاء إجابة من الضيف');
            final RTCSessionDescription answer = await _peerConnection!.createAnswer();

            print('تعيين الإجابة كوصف محلي');
            await _peerConnection!.setLocalDescription(answer);

            print('إرسال الإجابة إلى المضيف');
            await _database
                .child('sessions')
                .child(sessionId)
                .child('answer')
                .set(answer.toMap());

            // تخزين نسخة من الإجابة للاستخدام لاحقًا إذا لزم الأمر
            await _database
                .child('sessions')
                .child(sessionId)
                .child('lastAnswer')
                .set({
              'sdp': answer.sdp,
              'type': answer.type,
              'timestamp': DateTime.now().millisecondsSinceEpoch
            });
          } else {
            print('تجاهل SDP البعيد بسبب حالة الإشارة غير المتوافقة');
          }

          print('تم معالجة SDP البعيد بنجاح');
        } catch (e) {
          print('خطأ أثناء معالجة SDP البعيد: $e');
        }
      }
    });
  }
  // إرسال مرشح ICE
  Future<void> _sendIceCandidate(
      String sessionId, bool isHost, RTCIceCandidate candidate) async {
    final String role = isHost ? 'host' : 'guest';

    try {
      print('إرسال مرشح ICE كـ $role: ${candidate.candidate!.substring(0, Math.min(candidate.candidate!.length, 50))}...');

      await _database
          .child('sessions')
          .child(sessionId)
          .child('candidates')
          .child(role)
          .push()
          .set(candidate.toMap());
    } catch (e) {
      print('خطأ في إرسال مرشح ICE: $e');
    }
  }

  // الاستماع لمرشحي ICE البعيدة
  void _listenForRemoteIceCandidates(String sessionId, bool isHost) {
    final String remoteRole = isHost ? 'guest' : 'host';

    print('بدء الاستماع لمرشحي ICE من $remoteRole');

    _database
        .child('sessions')
        .child(sessionId)
        .child('candidates')
        .child(remoteRole)
        .onChildAdded
        .listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        try {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);

          if (data['candidate'] != null && data['sdpMid'] != null) {
            print('استلام مرشح ICE جديد من $remoteRole');

            final RTCIceCandidate candidate = RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            );

            _peerConnection!.addCandidate(candidate);
          }
        } catch (e) {
          print('خطأ في معالجة مرشح ICE: $e');
        }
      }
    });
  }

  // طلب إجابة جديدة
  Future<void> _requestAnswer(String sessionId) async {
    try {
      print('طلب إجابة جديدة من الضيف...');
      await _database
          .child('sessions')
          .child(sessionId)
          .child('requestAnswer')
          .set(DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('خطأ في طلب إجابة جديدة: $e');
    }
  }

  // إعادة إرسال الإجابة (للضيف)
  Future<void> _resendAnswer(String sessionId) async {
    try {
      print('محاولة إعادة إرسال الإجابة...');

      // التحقق من وجود إجابة سابقة
      final snapshot = await _database
          .child('sessions')
          .child(sessionId)
          .child('lastAnswer')
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final lastAnswer = Map<String, dynamic>.from(snapshot.value as Map);

        print('إعادة إرسال الإجابة السابقة');
        await _database
            .child('sessions')
            .child(sessionId)
            .child('answer')
            .set({
          'sdp': lastAnswer['sdp'],
          'type': lastAnswer['type']
        });
      } else {
        print('لا توجد إجابة سابقة، إعادة معالجة العرض');

        // الحصول على العرض وإعادة معالجته
        final offerSnapshot = await _database
            .child('sessions')
            .child(sessionId)
            .child('offer')
            .get();

        if (offerSnapshot.exists && offerSnapshot.value != null) {
          final offerData = Map<String, dynamic>.from(offerSnapshot.value as Map);

          // إعادة إنشاء الإجابة
          final answer = await handleOffer(offerData);

          // إرسال الإجابة الجديدة
          await _database
              .child('sessions')
              .child(sessionId)
              .child('answer')
              .set(answer);
        }
      }
    } catch (e) {
      print('خطأ في إعادة إرسال الإجابة: $e');
    }
  }

  // تبديل الميكروفون
  void toggleMic() {
    if (_localStream != null) {
      final audioTracks = _localStream!
          .getAudioTracks();

      if (audioTracks.isNotEmpty) {
        final audioTrack = audioTracks.firstWhere(
                (track) => track.kind == 'audio',
            orElse: () => throw Exception('لم يتم العثور على مسار صوتي')
        );

        _isMicEnabled = !_isMicEnabled;
        audioTrack.enabled = _isMicEnabled;
        print('تبديل الميكروفون: $_isMicEnabled');
        notifyListeners();
      }
    }
  }

// تبديل الكاميرا
  void toggleCamera() {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();

      if (videoTracks.isNotEmpty) {
        final videoTrack = videoTracks.firstWhere(
                (track) => track.kind == 'video',
            orElse: () => throw Exception('لم يتم العثور على مسار فيديو')
        );

        _isCameraEnabled = !_isCameraEnabled;
        videoTrack.enabled = _isCameraEnabled;
        print('تبديل الكاميرا: $_isCameraEnabled');
        notifyListeners();
      }
    }
  }

// تبديل الكاميرا الأمامية والخلفية
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();

      if (videoTracks.isNotEmpty) {
        final videoTrack = videoTracks.firstWhere(
                (track) => track.kind == 'video',
            orElse: () => throw Exception('لم يتم العثور على مسار فيديو')
        );

        await Helper.switchCamera(videoTrack);
        _isFrontCamera = !_isFrontCamera;
        print('تبديل اتجاه الكاميرا: ${_isFrontCamera ? "أمامية" : "خلفية"}');
        notifyListeners();
      }
    }
  }
// تعديل دالة dispose في WebRTCProvider
  Future<void> dispose() async {
    print('بدء تنظيف موارد WebRTC...');

    try {
      _isConnectionEstablished = false;

      // 1. إيقاف جميع المسارات أولاً
      if (_localStream != null) {
        await _stopAllTracks(_localStream!);
      }

      // 2. إزالة المسارات من PeerConnection قبل إغلاقه
      if (_peerConnection != null) {
        try {
          // إزالة جميع المسارات
          final senders = await _peerConnection!.getSenders();
          for (final sender in senders) {
            if (sender.track != null) {
              await sender.track!.stop();
              await _peerConnection!.removeTrack(sender);
            }
          }

          // إغلاق الاتصال
          await _peerConnection!.close();
          _peerConnection = null;
        } catch (e) {
          print('خطأ في إغلاق PeerConnection: $e');
        }
      }

      // 3. تنظيف المحركات
      await _safelyDisposeRenderer(_localRenderer);
      await _safelyDisposeRenderer(_remoteRenderer);

      // 4. تنظيف المتغيرات
      _localStream = null;
      _localRenderer = null;
      _remoteRenderer = null;

      print('تم تنظيف موارد WebRTC بنجاح');

      // 5. إعادة تهيئة المحركات للاستخدام التالي
      await initRenderers();

    } catch (e) {
      print('خطأ في تحرير الموارد: $e');
    }
  }

// دالة محسنة لإيقاف المسارات
  Future<void> _stopAllTracks(MediaStream stream) async {
    try {
      final tracks = stream.getTracks();
      print('إيقاف ${tracks.length} مسار وسائط');

      for (final track in tracks) {
        try {
          print('إيقاف مسار: ${track.kind}');
          await track.stop();
          stream.removeTrack(track);
        } catch (e) {
          print('خطأ في إيقاف المسار: $e');
        }
      }

      // التأكد من تدمير الـ stream
      await stream.dispose();
    } catch (e) {
      print('خطأ في إيقاف المسارات: $e');
    }
  }

// تحسين دالة _safelyDisposeRenderer
  Future<void> _safelyDisposeRenderer(RTCVideoRenderer? renderer) async {
    if (renderer != null) {
      try {
        // إزالة أي مصدر فيديو
        renderer.srcObject = null;

        // انتظار قصير للتأكد من التنظيف
        await Future.delayed(const Duration(milliseconds: 100));

        // التخلص من المحرك
        await renderer.dispose();
      } catch (e) {
        print('خطأ في التخلص من المحرك: $e');
      }
    }
  }

  // دالة مساعدة للتخلص من المسارات بأمان
  Future<void> _safelyStopTracks(MediaStream stream) async {
    try {
      final tracks = stream.getTracks();
      for (final track in tracks) {
        await track.stop();
      }
    } catch (e) {
      print('خطأ في إيقاف المسارات: $e');
    }
  }

// تعديل في WebRTCProvider
  Future<void> reinitialize() async {
    try {
      // تنظيف سريع بدلاً من dispose كامل
      _isConnectionEstablished = false;

      // إذا كانت المحركات موجودة ولم يتم التخلص منها، لا تعيد إنشاءها
      if (_localRenderer != null && _remoteRenderer != null) {
        // فقط أعد تعيين المحتوى
        try {
          _localRenderer!.srcObject = null;
          _remoteRenderer!.srcObject = null;
        } catch (e) {
          // إذا فشل، أعد إنشاء المحركات
          await _recreateRenderers();
        }
      } else {
        await _recreateRenderers();
      }

      // إعادة تعيين الحالات
      _isMicEnabled = true;
      _isCameraEnabled = true;
      _isConnectionEstablished = false;

      print('تمت إعادة تهيئة WebRTC بشكل محسن');
      notifyListeners();
    } catch (e) {
      print('خطأ في إعادة التهيئة المحسنة: $e');
      // في حالة الفشل، استخدم إعادة التهيئة الكاملة
      await dispose();
      await initRenderers();
    }
  }

  Future<void> _recreateRenderers() async {
    _localRenderer = RTCVideoRenderer();
    _remoteRenderer = RTCVideoRenderer();

    await _localRenderer!.initialize();
    await _remoteRenderer!.initialize();
  }

  // تطبيق فلتر على الفيديو
  Future<void> applyVideoFilter(String filterName) async {
    if (_localStream == null) return;

    _activeFilter = filterName;
    _isFilterApplied = filterName != 'none';

    // هنا يمكن استخدام WebRTC RTCVideoProcessor أو RTCRtpSender لتطبيق الفلاتر
    // لكن في هذا المثال سنكتفي بتحديث الحالة فقط وسيتم تطبيق الفلترات من خلال وسائل CSS في واجهة المستخدم

    notifyListeners();
  }

// إزالة فلتر الفيديو
  Future<void> removeVideoFilter() async {
    await applyVideoFilter('none');
  }

  // أضف هذه الدالة إلى WebRTCProvider
  Future<void> cleanupConnection() async {
    print('تنظيف اتصال WebRTC بدون إعادة تهيئة كاملة...');

    try {
      _isConnectionEstablished = false;

      // إيقاف المسارات فقط دون التخلص من الـ Stream
      if (_localStream != null) {
        // لا نقوم بـ dispose للـ localStream، فقط نوقف الاتصال
      }

      // إغلاق اتصال النظير إذا كان موجوداً
      if (_peerConnection != null) {
        await _peerConnection!.close();
        _peerConnection = null;
      }

      // تنظيف الـ remote renderer فقط
      if (_remoteRenderer != null) {
        _remoteRenderer!.srcObject = null;
      }

      print('تم تنظيف اتصال WebRTC بنجاح');
      notifyListeners();

    } catch (e) {
      print('خطأ في تنظيف اتصال WebRTC: $e');
    }
  }

}

// استيراد Math للحصول على وظيفة min
class Math {
  static int min(int a, int b) => a < b ? a : b;
}
