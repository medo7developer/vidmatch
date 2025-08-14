import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'firebase_service.dart';

class WebRTCService {
  final FirebaseService _firebaseService = FirebaseService();

  // تكوين إعدادات STUN/TURN
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': ['stun:stun1.l.google.com:19302']},
      {'urls': ['stun:stun2.l.google.com:19302']},
    ],
  };

  // تكوين إعدادات SDP
  final Map<String, dynamic> _offerSdpConstraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  // إنشاء اتصال نظير لنظير
  Future<RTCPeerConnection> createPeerConnection(Map<String, dynamic> configuration, Map<String, dynamic> offerSdpConstraints) async {
    return await createPeerConnection(_configuration, _offerSdpConstraints);
  }

  // إنشاء عرض SDP
  Future<RTCSessionDescription> createOffer(
      RTCPeerConnection peerConnection) async {
    return await peerConnection.createOffer(_offerSdpConstraints);
  }

  // إنشاء إجابة SDP
  Future<RTCSessionDescription> createAnswer(
      RTCPeerConnection peerConnection) async {
    return await peerConnection.createAnswer();
  }

  // تعيين وصف محلي
  Future<void> setLocalDescription(
      RTCPeerConnection peerConnection, RTCSessionDescription description) async {
    await peerConnection.setLocalDescription(description);
  }

  // تعيين وصف بعيد
  Future<void> setRemoteDescription(
      RTCPeerConnection peerConnection, RTCSessionDescription description) async {
    await peerConnection.setRemoteDescription(description);
  }

  // إضافة مرشح ICE
  Future<void> addIceCandidate(
      RTCPeerConnection peerConnection, RTCIceCandidate candidate) async {
    await peerConnection.addCandidate(candidate);
  }

  // إغلاق الاتصال
  Future<void> closeConnection(RTCPeerConnection peerConnection) async {
    await peerConnection.close();
  }
}
