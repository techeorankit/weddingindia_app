import 'dart:developer' as dev;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FirebaseService {
  static final _db = FirebaseFirestore.instance;
  static final _fcm = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Chat room ID - always smaller userId first
  static String chatRoomId(int uid1, int uid2) =>
      uid1 < uid2 ? '${uid1}_$uid2' : '${uid2}_$uid1';

  static Future<void> sendMessage({
    required int fromUserId,
    required int toUserId,
    required String fromName,
    required String text,
  }) async {
    try {
      final roomId = chatRoomId(fromUserId, toUserId);
      dev.log('Sending message roomId: $roomId from: $fromUserId to: $toUserId', name: 'Firebase');
      final now = FieldValue.serverTimestamp();

      await _db
          .collection('chats')
          .doc(roomId)
          .collection('messages')
          .add({
        'from': fromUserId,
        'text': text,
        'timestamp': now,
        'read': false,
      });

      await _db.collection('chats').doc(roomId).set({
        'users': [fromUserId, toUserId],
        'lastMessage': text,
        'lastMessageTime': now,
        'lastMessageFrom': fromUserId,
      }, SetOptions(merge: true));

      await _createActivity(
        fromUserId: fromUserId,
        toUserId: toUserId,
        fromName: fromName,
        type: 'message',
        message: '$fromName sent you a message',
      );

      dev.log('Message sent successfully', name: 'Firebase');
    } catch (e) {
      dev.log('sendMessage error: $e', name: 'Firebase');
    }
  }

  static Stream<QuerySnapshot> getMessages(int uid1, int uid2) {
    final roomId = chatRoomId(uid1, uid2);
    return _db
        .collection('chats')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
  static Stream<QuerySnapshot> getUserChats(int userId) {
    return _db
        .collection('chats')
      .where('users', arrayContains: userId)
        .snapshots();
  }

  // ─── ACTIVITY / NOTIFICATIONS ───────────────────────────

  static Future<void> sendActivityNotification({
    required int fromUserId,
    required int toUserId,
    required String fromName,
    required String type,
  }) async {
    final message = {
      'interest': '$fromName sent you an interest',
      'shortlist': '$fromName shortlisted you',
      'ignore': '$fromName ignored you',
    }[type] ?? '$fromName sent you an update';

    await _createActivity(
      fromUserId: fromUserId,
      toUserId: toUserId,
      fromName: fromName,
      type: type,
      message: message,
    );
  }

  static Future<void> respondToActivity({
    required String activityId,
    required int fromUserId,
    required int toUserId,
    required String fromName,
    required String response,
  }) async {
    final message = response == 'accepted'
        ? '$fromName accepted your interest'
        : '$fromName rejected your interest';

    await _db.collection('activities').doc(activityId).update({
      'response': response,
      'respondedAt': FieldValue.serverTimestamp(),
    });
    await _createActivity(
      fromUserId: fromUserId,
      toUserId: toUserId,
      fromName: fromName,
      type: response,
      message: message,
    );
  }

  static Future<void> _createActivity({
    required int fromUserId,
    required int toUserId,
    required String fromName,
    required String type,
    required String message,
  }) async {
    await _db.collection('activities').add({
      'toUserId': toUserId,
      'fromUserId': fromUserId,
      'fromName': fromName,
      'type': type,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
    });
    await _sendNotification(
      toUserId: toUserId,
      title: 'Wedding India',
      body: message,
      type: type,
      fromUserId: fromUserId,
    );
  }

  static Stream<QuerySnapshot> getActivities(int userId) {
    return _db
        .collection('activities')
        .where('toUserId', isEqualTo: userId)
        .snapshots();
  }
  static Future<void> saveFcmToken(int userId) async {
    final token = await _fcm.getToken();
    if (token != null) {
      await _db.collection('fcm_tokens').doc(userId.toString()).set({
        'token': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> _sendNotification({
    required int toUserId,
    required String title,
    required String body,
    required String type,
    required int fromUserId,
  }) async {
    final doc = await _db.collection('fcm_tokens').doc(toUserId.toString()).get();
    if (!doc.exists) return;
  }
  static Future<void> init(int userId) async {
    if (_initialized) return;

    await _fcm.requestPermission();
    await saveFcmToken(userId);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _localNotif.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    var initialActivitySnapshot = true;
    _db.collection('activities').where('toUserId', isEqualTo: userId).snapshots()
        .listen((snapshot) {
      if (initialActivitySnapshot) {
        initialActivitySnapshot = false;
        return;
      }
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data() ?? <String, dynamic>{};
        _showLocalNotification(
          data['message']?.toString() ?? 'You have a new notification',
        );
      }
    });

    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n == null) return;
      _localNotif.show(
        0,
        n.title,
        n.body,
        const NotificationDetails(
          android: AndroidNotificationDetails('wedding_india', 'Wedding India',
              importance: Importance.high, priority: Priority.high),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });
    _initialized = true;
  }

  static Future<void> _showLocalNotification(String body) async {
    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      'Wedding India',
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails('wedding_india', 'Wedding India',
            importance: Importance.high, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
