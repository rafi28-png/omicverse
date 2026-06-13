import 'dart:math';

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

  /// Generate a 6-character session code
  static String generateSessionCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    return List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
  }

  /// Create a new session (demo mode)
  static Future<CollaborationSession> createSession({
    required String title,
    required String creatorId,
    required String creatorName,
  }) async {
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
  }

  /// Join session by code (demo mode)
  static Future<CollaborationSession?> joinSession({
    required String sessionCode,
    required String userId,
    required String displayName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // In demo mode, create a simulated session
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
  }

  /// Add annotation (demo mode — in production uses Supabase Realtime)
  static SessionAnnotation createAnnotation({
    required String sessionId,
    required String userId,
    required String authorName,
    required String content,
    String? targetModule,
    String? targetGene,
  }) {
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
