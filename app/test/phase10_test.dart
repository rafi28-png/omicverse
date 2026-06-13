import 'package:flutter_test/flutter_test.dart';
import 'package:omicverse/features/collaboration/services/collaboration_service.dart';

void main() {
  group('CollaborationService', () {
    test('generateSessionCode returns 6 chars', () {
      final code = CollaborationService.generateSessionCode();
      expect(code.length, 6);
      expect(RegExp(r'^[A-Z2-9]+$').hasMatch(code), isTrue);
    });

    test('session codes are unique', () {
      final codes = List.generate(100, (_) => CollaborationService.generateSessionCode());
      expect(codes.toSet().length, greaterThan(90)); // Should be mostly unique
    });

    test('createSession returns valid session', () async {
      final session = await CollaborationService.createSession(
        title: 'Test Session', creatorId: 'user1', creatorName: 'Dr. Test');
      expect(session.title, 'Test Session');
      expect(session.sessionCode.length, 6);
      expect(session.participants.length, 1);
      expect(session.participants[0].role, 'owner');
    });

    test('joinSession returns session with 2 participants', () async {
      final session = await CollaborationService.joinSession(
        sessionCode: 'ABC123', userId: 'user2', displayName: 'Dr. Join');
      expect(session, isNotNull);
      expect(session!.participants.length, 2);
      expect(session.participants[1].displayName, 'Dr. Join');
      expect(session.participants[1].role, 'editor');
    });

    test('createAnnotation returns valid annotation', () {
      final ann = CollaborationService.createAnnotation(
        sessionId: 's1', userId: 'u1', authorName: 'Dr. A',
        content: 'Test note', targetModule: 'Cancer', targetGene: 'TP53');
      expect(ann.content, 'Test note');
      expect(ann.targetGene, 'TP53');
      expect(ann.authorName, 'Dr. A');
    });

    test('demoAnnotations returns valid list', () {
      final anns = CollaborationService.demoAnnotations();
      expect(anns.length, 3);
      for (final a in anns) {
        expect(a.content, isNotEmpty);
        expect(a.authorName, isNotEmpty);
      }
    });
  });

  group('SessionParticipant', () {
    test('roleLabel capitalizes correctly', () {
      final p = SessionParticipant(id: 'p1', userId: 'u1',
        displayName: 'Test', role: 'owner', joinedAt: DateTime.now());
      expect(p.roleLabel, 'Owner');
    });
  });

  group('CollaborationSession', () {
    test('session properties work', () async {
      final session = await CollaborationService.createSession(
        title: 'Props Test', creatorId: 'u1', creatorName: 'Dr. X');
      expect(session.isActive, isTrue);
      expect(session.participantCount, 1);
    });
  });
}
