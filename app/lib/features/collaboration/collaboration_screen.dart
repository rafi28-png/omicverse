import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/glow_card.dart';
import '../../core/widgets/neon_button.dart';
import '../../core/widgets/module_header.dart';
import '../../core/widgets/research_disclaimer.dart';
import '../../core/widgets/dna_loader.dart';
import '../../core/providers/app_providers.dart';
import 'services/collaboration_service.dart';

enum _ScreenState { lobby, creating, joining, inSession }

class CollaborationScreen extends ConsumerStatefulWidget {
  const CollaborationScreen({super.key});
  @override
  ConsumerState<CollaborationScreen> createState() => _CollaborationScreenState();
}

class _CollaborationScreenState extends ConsumerState<CollaborationScreen> {
  _ScreenState _state = _ScreenState.lobby;
  CollaborationSession? _session;
  List<SessionAnnotation> _annotations = [];
  final _titleCtrl = TextEditingController(text: 'Research Session');
  final _codeCtrl = TextEditingController();
  final _annotCtrl = TextEditingController();
  final _nameCtrl = TextEditingController(text: 'Researcher');
  
  StreamSubscription<List<Map<String, dynamic>>>? _annotationsSub;
  final Map<String, String> _userNames = {};

  @override
  void dispose() {
    _annotationsSub?.cancel();
    _titleCtrl.dispose(); _codeCtrl.dispose();
    _annotCtrl.dispose(); _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createSession() async {
    setState(() => _state = _ScreenState.creating);
    final isDemoMode = ref.read(isDemoModeProvider);
    final userId = isDemoMode
        ? 'demo_user'
        : (Supabase.instance.client.auth.currentUser?.id ?? 'demo_user');
    final creatorName = _nameCtrl.text.trim();

    try {
      final session = await CollaborationService.createSession(
        title: _titleCtrl.text.trim(),
        creatorId: userId,
        creatorName: creatorName,
        isDemoMode: isDemoMode,
      );
      _setupSession(session, isDemoMode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create session: $e')),
        );
        setState(() => _state = _ScreenState.lobby);
      }
    }
  }

  Future<void> _joinSession() async {
    if (_codeCtrl.text.trim().length != 6) return;
    setState(() => _state = _ScreenState.joining);
    final isDemoMode = ref.read(isDemoModeProvider);
    final userId = isDemoMode
        ? 'demo_user'
        : (Supabase.instance.client.auth.currentUser?.id ?? 'demo_user');

    try {
      final session = await CollaborationService.joinSession(
        sessionCode: _codeCtrl.text.trim().toUpperCase(),
        userId: userId,
        displayName: _nameCtrl.text.trim(),
        isDemoMode: isDemoMode,
      );
      _setupSession(session, isDemoMode);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join session: $e')),
        );
        setState(() => _state = _ScreenState.lobby);
      }
    }
  }

  void _setupSession(CollaborationSession? session, bool isDemoMode) {
    if (session == null) {
      setState(() => _state = _ScreenState.lobby);
      return;
    }

    _session = session;
    _annotations = isDemoMode ? CollaborationService.demoAnnotations() : [];

    if (!isDemoMode) {
      for (final p in session.participants) {
        _userNames[p.userId] = p.displayName;
      }

      _annotationsSub = Supabase.instance.client
          .from('session_annotations')
          .stream(primaryKey: ['id'])
          .eq('session_id', session.id)
          .order('created_at', ascending: true)
          .listen((data) {
            final list = <SessionAnnotation>[];
            for (final row in data) {
              final uid = row['user_id'] as String;
              String name = _userNames[uid] ?? 'Researcher';

              if (!_userNames.containsKey(uid)) {
                _userNames[uid] = 'Researcher';
                Supabase.instance.client
                    .from('profiles')
                    .select('name')
                    .eq('id', uid)
                    .maybeSingle()
                    .then((profile) {
                      if (profile != null && profile['name'] != null) {
                        final n = profile['name'] as String;
                        if (n.isNotEmpty && mounted) {
                          setState(() {
                            _userNames[uid] = n;
                          });
                        }
                      }
                    });
              }

              list.add(SessionAnnotation(
                id: row['id'] as String,
                sessionId: row['session_id'] as String,
                userId: uid,
                authorName: name,
                content: row['note_text'] as String? ?? '',
                targetModule: row['screen'] as String?,
                createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
              ));
            }
            if (mounted) {
              setState(() {
                _annotations = list;
              });
            }
          });
    }

    setState(() {
      _state = _ScreenState.inSession;
    });
  }

  void _addAnnotation() {
    if (_annotCtrl.text.trim().isEmpty) return;
    final isDemoMode = ref.read(isDemoModeProvider);
    final userId = isDemoMode
        ? 'demo_user'
        : (Supabase.instance.client.auth.currentUser?.id ?? 'demo_user');

    final ann = CollaborationService.createAnnotation(
      sessionId: _session!.id,
      userId: userId,
      authorName: _nameCtrl.text.trim(),
      content: _annotCtrl.text.trim(),
      isDemoMode: isDemoMode,
    );
    if (isDemoMode) {
      setState(() { _annotations.add(ann); _annotCtrl.clear(); });
    } else {
      _annotCtrl.clear();
    }
  }

  void _leaveSession() {
    _annotationsSub?.cancel();
    _annotationsSub = null;
    _userNames.clear();
    setState(() { _state = _ScreenState.lobby; _session = null; _annotations = []; });
  }

  @override
  Widget build(BuildContext context) {
    final isDemoMode = ref.watch(isDemoModeProvider);
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(backgroundColor: kBackground, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => context.go('/home')),
        title: Text('Collaboration', style: tsTitle(kTextPrimary)),
        actions: [
          if (_state == _ScreenState.inSession)
            IconButton(icon: const Icon(Icons.exit_to_app, color: kNeonRed),
              onPressed: _leaveSession),
        ]),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            ModuleHeader(title: 'Realtime Collaboration',
              subtitle: 'Share sessions & annotate together',
              gradientColors: const [kNeonPurple, kNeonTeal], icon: Icons.groups, isDemoMode: isDemoMode),
            const SizedBox(height: 12),
            // Experimental notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kNeonAmber.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kNeonAmber.withValues(alpha: 0.3))),
              child: Row(children: [
                const Icon(Icons.science, color: kNeonAmber, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('Collaboration is experimental. '
                  'Requires Supabase Realtime (configured in Phase 3).',
                  style: tsBody().copyWith(fontSize: 12, color: kNeonAmber))),
              ])),
            const SizedBox(height: 24),
            _buildBody(),
            const SizedBox(height: 24),
            const ResearchDisclaimer(),
          ]),
        )),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case _ScreenState.lobby:
        return _buildLobby();
      case _ScreenState.creating:
      case _ScreenState.joining:
        return const Center(child: DnaLoader(message: 'Connecting...'));
      case _ScreenState.inSession:
        return _buildSession();
    }
  }

  Widget _buildLobby() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Name
      TextField(
        controller: _nameCtrl,
        decoration: InputDecoration(
          labelText: 'Your Display Name',
          labelStyle: tsLabel(), filled: true, fillColor: kSurface,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
        style: tsBody()),
      const SizedBox(height: 20),

      // Create session
      GlowCard(glowColor: kNeonPurple, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('CREATE SESSION', style: tsLabel()),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              hintText: 'Session title',
              hintStyle: tsBody().copyWith(color: kTextMuted),
              filled: true, fillColor: kSurfaceRaised,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            style: tsBody()),
          const SizedBox(height: 12),
          NeonButton(label: 'Create & Share', icon: Icons.add, color: kNeonPurple, onPressed: _createSession),
        ])),
      const SizedBox(height: 16),

      // Join session
      GlowCard(glowColor: kNeonTeal, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('JOIN SESSION', style: tsLabel()),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: InputDecoration(
                hintText: '6-char code',
                hintStyle: tsBody().copyWith(color: kTextMuted),
                counterText: '',
                filled: true, fillColor: kSurfaceRaised,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
              style: tsMono().copyWith(fontSize: 16, letterSpacing: 4))),
            const SizedBox(width: 12),
            NeonButton(label: 'Join', icon: Icons.login, color: kNeonTeal, onPressed: _joinSession),
          ]),
        ])),
    ]);
  }

  Widget _buildSession() {
    final s = _session!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Session info
      GlowCard(glowColor: kNeonPurple, child: Row(children: [
        Container(width: 50, height: 50,
          decoration: const BoxDecoration(shape: BoxShape.circle,
            gradient: LinearGradient(colors: [kNeonPurple, kNeonTeal])),
          child: const Center(child: Icon(Icons.groups, color: kVoid, size: 24))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(s.title, style: tsBody().copyWith(fontWeight: FontWeight.w700)),
          Row(children: [
            Text('Code: ', style: tsLabel()),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: kNeonPurple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4)),
              child: Text(s.sessionCode, style: tsMono().copyWith(
                fontSize: 16, letterSpacing: 3, color: kNeonPurple, fontWeight: FontWeight.w700))),
          ]),
        ])),
      ])),
      const SizedBox(height: 16),

      // Participants (presence indicator)
      Text('PARTICIPANTS', style: tsLabel()),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8,
        children: s.participants.map((p) => GlowCard(
          glowColor: p.isOnline ? kNeonGreen : kTextMuted,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 8, height: 8,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: p.isOnline ? kNeonGreen : kTextMuted)),
            const SizedBox(width: 8),
            Text(p.displayName, style: tsBody().copyWith(fontSize: 12)),
            const SizedBox(width: 6),
            Text(p.roleLabel, style: tsBadge().copyWith(
              color: p.role == 'owner' ? kNeonGold : kTextSecondary)),
          ]),
        )).toList()),
      const SizedBox(height: 16),

      // Annotations
      Text('ANNOTATIONS', style: tsLabel()),
      const SizedBox(height: 8),
      ..._annotations.map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GlowCard(
          glowColor: a.userId == 'demo_user' ? kNeonTeal : kNeonPurple,
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(a.authorName, style: tsBody().copyWith(
                fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(width: 8),
              if (a.targetModule != null)
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: kNeonPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4)),
                  child: Text(a.targetModule!, style: tsBadge().copyWith(color: kNeonPurple, fontSize: 8))),
              if (a.targetGene != null) ...[
                const SizedBox(width: 4),
                Text(a.targetGene!, style: tsMono().copyWith(fontSize: 10, color: kNeonGreen)),
              ],
              const Spacer(),
              Text(_timeAgo(a.createdAt), style: tsLabel().copyWith(fontSize: 8)),
            ]),
            const SizedBox(height: 4),
            Text(a.content, style: tsBody().copyWith(fontSize: 12)),
          ]),
        ),
      )),
      const SizedBox(height: 8),

      // Add annotation
      Row(children: [
        Expanded(child: TextField(
          controller: _annotCtrl,
          decoration: InputDecoration(
            hintText: 'Add annotation...',
            hintStyle: tsBody().copyWith(color: kTextMuted, fontSize: 12),
            filled: true, fillColor: kSurface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kBorder)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          style: tsBody().copyWith(fontSize: 12),
          onSubmitted: (_) => _addAnnotation())),
        const SizedBox(width: 8),
        NeonButton(label: 'Send', icon: Icons.send, color: kNeonTeal, onPressed: _addAnnotation),
      ]),
    ]);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
