import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class CollaborationSession {
  final String id;
  final String sessionCode;
  final String creatorId;
  final String title;
  final DateTime createdAt;
  final List<SessionParticipant> participants;
  final List<SessionAnnotation> annotations;
  final bool presenterMode;

  const CollaborationSession({
    required this.id,
    required this.sessionCode,
    required this.creatorId,
    required this.title,
    required this.createdAt,
    this.participants = const [],
    this.annotations = const [],
    this.presenterMode = false,
  });

  bool get isActive => participants.isNotEmpty;
  int get participantCount => participants.length;
}

class SessionParticipant {
  final String id;
  final String userId;
  final String displayName;
  final String role; // owner, editor, viewer
  final bool isOnline;
  final DateTime joinedAt;

  const SessionParticipant({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.role,
    this.isOnline = true,
    required this.joinedAt,
  });

  String get roleLabel => role[0].toUpperCase() + role.substring(1);
}

class SessionAnnotation {
  final String id;
  final String sessionId;
  final String userId;
  final String authorName;
  final String content;
  final String? targetModule;
  final String? targetGene;
  final DateTime createdAt;

  const SessionAnnotation({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.authorName,
    required this.content,
    this.targetModule,
    this.targetGene,
    required this.createdAt,
  });
}

class CollaborationService {
  static final _random = Random();
  static SupabaseClient get _sb => Supabase.instance.client;

  /// Generate a 6-character session code
  static String generateSessionCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  /// Create a new session (real + demo mode)
  static Future<CollaborationSession> createSession({
    required String title,
    required String creatorId,
    required String creatorName,
    bool isDemoMode = true,
  }) async {
    if (isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      final now = DateTime.now();
      return CollaborationSession(
        id: 'session_${now.millisecondsSinceEpoch}',
        sessionCode: generateSessionCode(),
        creatorId: creatorId,
        title: title,
        createdAt: now,
        participants: [
          SessionParticipant(id: 'p1', userId: creatorId,
            displayName: creatorName, role: 'owner', joinedAt: now),
        ],
      );
    } else {
      final code = generateSessionCode();
      final now = DateTime.now();

      // 1. Insert session
      final sessionInsert = await _sb.from('collaboration_sessions').insert({
        'session_code': code,
        'creator_id': creatorId,
        'title': title,
        'module': 'collaboration',
        'is_active': true,
      }).select().single();

      final sessionId = sessionInsert['id'] as String;

      // 2. Insert participant (creator)
      await _sb.from('session_participants').insert({
        'session_id': sessionId,
        'user_id': creatorId,
      });

      return CollaborationSession(
        id: sessionId,
        sessionCode: code,
        creatorId: creatorId,
        title: title,
        createdAt: now,
        participants: [
          SessionParticipant(
            id: '${sessionId}_$creatorId',
            userId: creatorId,
            displayName: creatorName,
            role: 'owner',
            joinedAt: now,
          ),
        ],
      );
    }
  }

  /// Join session by code (real + demo mode)
  static Future<CollaborationSession?> joinSession({
    required String sessionCode,
    required String userId,
    required String displayName,
    bool isDemoMode = true,
  }) async {
    if (isDemoMode) {
      await Future.delayed(const Duration(milliseconds: 300));
      final now = DateTime.now();
      return CollaborationSession(
        id: 'session_joined',
        sessionCode: sessionCode,
        creatorId: 'other_user',
        title: 'Shared Session',
        createdAt: now.subtract(const Duration(minutes: 5)),
        participants: [
          SessionParticipant(id: 'p0', userId: 'other_user',
            displayName: 'Dr. Smith', role: 'owner',
            joinedAt: now.subtract(const Duration(minutes: 5))),
          SessionParticipant(id: 'p1', userId: userId,
            displayName: displayName, role: 'editor', joinedAt: now),
        ],
      );
    } else {
      // 1. Find session by code
      final sessions = await _sb
          .from('collaboration_sessions')
          .select()
          .eq('session_code', sessionCode)
          .eq('is_active', true);

      if (sessions.isEmpty) return null;
      final sessionRow = sessions.first;
      final sessionId = sessionRow['id'] as String;
      final creatorId = sessionRow['creator_id'] as String;

      // 2. Join participant if not already joined
      final existingPart = await _sb
          .from('session_participants')
          .select()
          .eq('session_id', sessionId)
          .eq('user_id', userId);

      if (existingPart.isEmpty) {
        await _sb.from('session_participants').insert({
          'session_id': sessionId,
          'user_id': userId,
        });
      }

      // 3. Fetch all current participants with profiles
      final participantsData = await _sb
          .from('session_participants')
          .select('*, profiles(name)')
          .eq('session_id', sessionId);

      final participants = <SessionParticipant>[];
      for (final p in participantsData) {
        final pUid = p['user_id'] as String;
        final profileMap = p['profiles'] as Map<String, dynamic>?;
        final pName = profileMap != null ? (profileMap['name'] as String? ?? '') : '';
        final isOwner = pUid == creatorId;
        participants.add(SessionParticipant(
          id: '${sessionId}_$pUid',
          userId: pUid,
          displayName: pName.isNotEmpty ? pName : 'Researcher',
          role: isOwner ? 'owner' : 'editor',
          joinedAt: DateTime.tryParse(p['joined_at'] as String? ?? '') ?? DateTime.now(),
        ));
      }

      return CollaborationSession(
        id: sessionId,
        sessionCode: sessionCode,
        creatorId: creatorId,
        title: sessionRow['title'] as String? ?? 'Shared Session',
        createdAt: DateTime.tryParse(sessionRow['created_at'] as String? ?? '') ?? DateTime.now(),
        participants: participants,
      );
    }
  }

  /// Add annotation (real + demo mode)
  static SessionAnnotation createAnnotation({
    required String sessionId,
    required String userId,
    required String authorName,
    required String content,
    String? targetModule,
    String? targetGene,
    bool isDemoMode = true,
  }) {
    if (isDemoMode) {
      return SessionAnnotation(
        id: 'ann_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        userId: userId,
        authorName: authorName,
        content: content,
        targetModule: targetModule,
        targetGene: targetGene,
        createdAt: DateTime.now(),
      );
    } else {
      // In live mode, insert into database asynchronously.
      // Realtime subscription handles rendering it.
      _sb.from('session_annotations').insert({
        'session_id': sessionId,
        'user_id': userId,
        'screen': targetModule ?? 'collaboration',
        'note_text': content,
      }).then((_) {});

      return SessionAnnotation(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        userId: userId,
        authorName: authorName,
        content: content,
        targetModule: targetModule,
        targetGene: targetGene,
        createdAt: DateTime.now(),
      );
    }
  }

  /// Demo annotations
  static List<SessionAnnotation> demoAnnotations() {
    final now = DateTime.now();
    return [
      SessionAnnotation(id: 'a1', sessionId: 's1', userId: 'u1',
        authorName: 'Dr. Smith', content: 'TP53 R175H hotspot confirmed in our cohort',
        targetModule: 'Cancer', targetGene: 'TP53',
        createdAt: now.subtract(const Duration(minutes: 10))),
      SessionAnnotation(id: 'a2', sessionId: 's1', userId: 'u2',
        authorName: 'Dr. Chen', content: 'BRCA1 methylation pattern looks abnormal',
        targetModule: 'Methylation', targetGene: 'BRCA1',
        createdAt: now.subtract(const Duration(minutes: 5))),
      SessionAnnotation(id: 'a3', sessionId: 's1', userId: 'u1',
        authorName: 'Dr. Smith', content: 'Check EGFR T790M for drug resistance',
        targetModule: 'Drug', targetGene: 'EGFR',
        createdAt: now.subtract(const Duration(minutes: 2))),
    ];
  }
}
