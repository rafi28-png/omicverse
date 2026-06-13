import 'dart:math' as math;
import 'package:flutter/material.dart';

// Backgrounds
const kVoid          = Color(0xFF020406);
const kBackground    = Color(0xFF060912);
const kSurface       = Color(0xFF0A1020);
const kSurfaceRaised = Color(0xFF0E1830);
const kSurfaceGlass  = Color(0x12FFFFFF);
const kBorder        = Color(0xFF1A2A44);
const kBorderHover   = Color(0xFF2A4060);

// Neon accents
const kNeonTeal    = Color(0xFF00FFB2);
const kNeonPurple  = Color(0xFF9B6DFF);
const kNeonPink    = Color(0xFFFF4ECD);
const kNeonBlue    = Color(0xFF00D4FF);
const kNeonGreen   = Color(0xFF39FF14);
const kNeonOrange  = Color(0xFFFF8C00);
const kNeonAmber   = Color(0xFFFFB347);
const kNeonRed     = Color(0xFFFF2D55);
const kNeonGold    = Color(0xFFFFD700);

// Text
const kTextPrimary   = Color(0xFFE8F0FF);
const kTextSecondary = Color(0xFF9BAABF);
const kTextMuted     = Color(0xFF5A6A7A);
const kTextGlow      = Color(0xFFAAFFEE);
const kTextCode      = Color(0xFF6FFFCF);

// Evidence tiers
const kTier1 = Color(0xFFFFD700);
const kTier2 = Color(0xFFC0C0C0);
const kTier3 = Color(0xFFCD7F32);
const kTier4 = Color(0xFF445566);

// Module gradient pairs
const kGradGenome     = [Color(0xFF00FFB2), Color(0xFF00D4FF)];
const kGradRegulatory = [Color(0xFF9B6DFF), Color(0xFFFF4ECD)];
const kGradProtein    = [Color(0xFF00D4FF), Color(0xFF9B6DFF)];
const kGradVariant    = [Color(0xFFFF2D55), Color(0xFFFF8C00)];
const kGradExpression = [Color(0xFF39FF14), Color(0xFF00FFB2)];
const kGradPathway    = [Color(0xFF9B6DFF), Color(0xFF00D4FF)];
const kGradCancer     = [Color(0xFFFF2D55), Color(0xFF9B6DFF)];
const kGradEvolution  = [Color(0xFFFFD700), Color(0xFFFF8C00)];
const kGradSplicing   = [Color(0xFFFF4ECD), Color(0xFF9B6DFF)];
const kGradDrug       = [Color(0xFF00D4FF), Color(0xFF39FF14)];
const kGradPopulation = [Color(0xFF00FFB2), Color(0xFFFFD700)];
const kGrad3DGenome   = [Color(0xFF9B6DFF), Color(0xFF00D4FF)];
const kGradPRS        = [Color(0xFFFFD700), Color(0xFFFF2D55)];
const kGradEpigenome  = [Color(0xFF00D4FF), Color(0xFF9B6DFF)];
const kGradCRISPR     = [Color(0xFF39FF14), Color(0xFF00D4FF)];

BoxShadow glowShadow(Color c, {double r = 20}) =>
  BoxShadow(color: c.withValues(alpha: 0.22), blurRadius: r);
BoxShadow depthShadow() =>
  BoxShadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 32,
    offset: const Offset(0, 8));

bool meetsContrastAA(Color text, Color background) {
  final tL = text.computeLuminance();
  final bL = background.computeLuminance();
  final lighter = math.max(tL, bL);
  final darker  = math.min(tL, bL);
  return (lighter + 0.05) / (darker + 0.05) >= 4.5;
}
