import 'package:flutter/material.dart';
import 'colors.dart';

TextStyle tsHero() => const TextStyle(
  fontFamily: 'Orbitron', fontSize: 36, fontWeight: FontWeight.w900,
  letterSpacing: -1, color: kTextGlow);

TextStyle tsTitle(Color c) => TextStyle(
  fontFamily: 'Orbitron', fontSize: 20, fontWeight: FontWeight.w700,
  letterSpacing: -0.5, color: c);

TextStyle tsSubtitle() => const TextStyle(
  fontFamily: 'IBMPlexSans', fontSize: 14, fontWeight: FontWeight.w500,
  color: kTextSecondary);

TextStyle tsBody() => const TextStyle(
  fontFamily: 'IBMPlexSans', fontSize: 13, fontWeight: FontWeight.w400,
  height: 1.75, color: kTextPrimary);

TextStyle tsMono() => const TextStyle(
  fontFamily: 'JetBrainsMono', fontSize: 12, color: kTextCode);

TextStyle tsLabel() => const TextStyle(
  fontFamily: 'Rajdhani', fontSize: 11, fontWeight: FontWeight.w600,
  letterSpacing: 2.5, color: kTextMuted);

TextStyle tsBadge() => const TextStyle(
  fontFamily: 'Rajdhani', fontSize: 10, fontWeight: FontWeight.w700,
  letterSpacing: 1.5);

TextStyle tsBigNumber(Color c) => TextStyle(
  fontFamily: 'Orbitron', fontSize: 48, fontWeight: FontWeight.w900, color: c,
  shadows: [Shadow(color: c.withValues(alpha: 0.5), blurRadius: 20)]);
