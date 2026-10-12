import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Data model representing a user-customizable or built-in theme.
@immutable
class UserThemeModel {
  final String id;
  final String name;
  final String fontFamily;
  final String scaffoldBgHex;
  final String cardBgHex;
  final String cardBorderHex;
  final String textPrimaryHex;
  final String textSecondaryHex;
  final List<String> accentPaletteHex;
  final bool isBuiltIn;
  final DateTime? lastModifiedAt;

  const UserThemeModel({
    required this.id,
    required this.name,
    required this.fontFamily,
    required this.scaffoldBgHex,
    required this.cardBgHex,
    required this.cardBorderHex,
    required this.textPrimaryHex,
    this.textSecondaryHex = '#94A3B8',
    required this.accentPaletteHex,
    this.isBuiltIn = false,
    this.lastModifiedAt,
  });

  // --- Convenience Color Getters ---
  Color get scaffoldBg => AppColors.hexToColor(
        scaffoldBgHex,
        fallback: AppColors.obsidianTwilight,
      );

  Color get cardBg => AppColors.hexToColor(
        cardBgHex,
        fallback: AppColors.cardSurface,
      );

  Color get cardBorder => AppColors.hexToColor(
        cardBorderHex,
        fallback: AppColors.borderSubtle,
      );

  Color get textPrimary => AppColors.hexToColor(
        textPrimaryHex,
        fallback: AppColors.textPrimary,
      );

  Color get textSecondary => AppColors.hexToColor(
        textSecondaryHex,
        fallback: AppColors.textSecondary,
      );

  List<Color> get accentPalette => accentPaletteHex
      .map((hex) => AppColors.hexToColor(hex, fallback: AppColors.neonLavender))
      .toList(growable: false);

  /// Determine if this theme is perceptually dark
  bool get isDark => scaffoldBg.computeLuminance() < 0.5;

  // --- CopyWith ---
  UserThemeModel copyWith({
    String? id,
    String? name,
    String? fontFamily,
    String? scaffoldBgHex,
    String? cardBgHex,
    String? cardBorderHex,
    String? textPrimaryHex,
    String? textSecondaryHex,
    List<String>? accentPaletteHex,
    bool? isBuiltIn,
    DateTime? lastModifiedAt,
  }) {
    return UserThemeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      fontFamily: fontFamily ?? this.fontFamily,
      scaffoldBgHex: scaffoldBgHex ?? this.scaffoldBgHex,
      cardBgHex: cardBgHex ?? this.cardBgHex,
      cardBorderHex: cardBorderHex ?? this.cardBorderHex,
      textPrimaryHex: textPrimaryHex ?? this.textPrimaryHex,
      textSecondaryHex: textSecondaryHex ?? this.textSecondaryHex,
      accentPaletteHex: accentPaletteHex != null
          ? List.unmodifiable(accentPaletteHex)
          : this.accentPaletteHex,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    );
  }

  // --- JSON Serialization ---
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'fontFamily': fontFamily,
      'scaffoldBg': scaffoldBgHex,
      'scaffoldBgHex': scaffoldBgHex,
      'cardBg': cardBgHex,
      'cardBgHex': cardBgHex,
      'cardBorder': cardBorderHex,
      'cardBorderHex': cardBorderHex,
      'textPrimary': textPrimaryHex,
      'textPrimaryHex': textPrimaryHex,
      'textSecondary': textSecondaryHex,
      'textSecondaryHex': textSecondaryHex,
      'accentGradients': accentPaletteHex,
      'accentPaletteHex': accentPaletteHex,
      'isBuiltIn': isBuiltIn,
      if (lastModifiedAt != null) 'lastModifiedAt': lastModifiedAt!.toIso8601String(),
    };
  }

  factory UserThemeModel.fromJson(Map<String, dynamic> json) {
    final rawAccents = json['accentPaletteHex'] as List<dynamic>? ??
        json['accentGradients'] as List<dynamic>?;

    final accents = rawAccents?.map((e) => e.toString()).toList(growable: false) ??
        const [
          '#FF6B55',
          '#8B5CF6',
          '#10B981',
          '#06B6D4',
          '#FFAE33',
          '#EC4899',
        ];

    return UserThemeModel(
      id: json['id'] as String? ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Custom Theme',
      fontFamily: json['fontFamily'] as String? ?? 'PlusJakartaSans',
      scaffoldBgHex: (json['scaffoldBgHex'] ?? json['scaffoldBg']) as String? ?? '#0F1016',
      cardBgHex: (json['cardBgHex'] ?? json['cardBg']) as String? ?? '#181924',
      cardBorderHex: (json['cardBorderHex'] ?? json['cardBorder']) as String? ?? '#262837',
      textPrimaryHex: (json['textPrimaryHex'] ?? json['textPrimary']) as String? ?? '#F8FAFC',
      textSecondaryHex: (json['textSecondaryHex'] ?? json['textSecondary']) as String? ?? '#94A3B8',
      accentPaletteHex: accents,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      lastModifiedAt: json['lastModifiedAt'] != null
          ? DateTime.parse(json['lastModifiedAt'] as String)
          : null,
    );
  }

  // --- Built-in Default Presets ---

  /// Reference 1: Serene Pastel & Deep Teal Mental Health Tracker
  static const UserThemeModel nordicSerenity = UserThemeModel(
    id: 'nordic_serenity',
    name: 'Nordic Serenity',
    fontFamily: 'PlusJakartaSans',
    scaffoldBgHex: '#EBF2F5',
    cardBgHex: '#FFFFFF',
    cardBorderHex: '#DCE5EA',
    textPrimaryHex: '#11252E',
    textSecondaryHex: '#5C6E76',
    accentPaletteHex: [
      '#0E4856', // Deep Nordic Petrol / Teal (Primary Anchor)
      '#8B5CF6', // Soft Lavender
      '#10B981', // Sage Mint
      '#06B6D4', // Powder Cyan
      '#FB7185', // Rose Quartz
      '#FFAE33', // Mango Amber
    ],
    isBuiltIn: true,
  );

  /// Reference 2: Warm Editorial Mindfulness & Peach Dawn Tracker
  static const UserThemeModel sunsetAurora = UserThemeModel(
    id: 'sunset_aurora',
    name: 'Sunset Aurora',
    fontFamily: 'PlusJakartaSans',
    scaffoldBgHex: '#FFF7F2',
    cardBgHex: '#FFFFFF',
    cardBorderHex: '#F5E2D8',
    textPrimaryHex: '#231924',
    textSecondaryHex: '#6E5A6A',
    accentPaletteHex: [
      '#FF6B55', // Sunset Coral
      '#FFAE33', // Mango Sunrise
      '#A855F7', // Ethereal Orchid
      '#FB7185', // Rose Quartz
      '#06B6D4', // Cyan Glow
      '#1E1B24', // Deep Onyx
    ],
    isBuiltIn: true,
  );

  /// Flagship Dark Obsidian / Dusk Aesthetic
  static const UserThemeModel obsidianTwilight = UserThemeModel(
    id: 'obsidian_twilight',
    name: 'Obsidian Twilight',
    fontFamily: 'PlusJakartaSans',
    scaffoldBgHex: '#0F1016',
    cardBgHex: '#181924',
    cardBorderHex: '#262837',
    textPrimaryHex: '#F8FAFC',
    textSecondaryHex: '#94A3B8',
    accentPaletteHex: [
      '#FF6B55', // Sunset Coral
      '#8B5CF6', // Neon Lavender
      '#10B981', // Emerald Mint
      '#06B6D4', // Cyan Glow
      '#FFAE33', // Mango Sunrise
      '#EC4899', // Bubblegum Pink
    ],
    isBuiltIn: true,
  );

  /// Crisp Minimal Daylight
  static const UserThemeModel porcelainSunrise = UserThemeModel(
    id: 'porcelain_sunrise',
    name: 'Porcelain Sunrise',
    fontFamily: 'Inter',
    scaffoldBgHex: '#F8F9FD',
    cardBgHex: '#FFFFFF',
    cardBorderHex: '#E2E8F0',
    textPrimaryHex: '#0F172A',
    textSecondaryHex: '#475569',
    accentPaletteHex: [
      '#FF6B55',
      '#8B5CF6',
      '#10B981',
      '#06B6D4',
      '#FFAE33',
      '#EC4899',
    ],
    isBuiltIn: true,
  );

  static List<UserThemeModel> get builtInPresets => const [
        nordicSerenity,
        sunsetAurora,
        obsidianTwilight,
        porcelainSunrise,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserThemeModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          fontFamily == other.fontFamily &&
          scaffoldBgHex == other.scaffoldBgHex &&
          cardBgHex == other.cardBgHex &&
          cardBorderHex == other.cardBorderHex &&
          textPrimaryHex == other.textPrimaryHex &&
          textSecondaryHex == other.textSecondaryHex &&
          isBuiltIn == other.isBuiltIn &&
          lastModifiedAt == other.lastModifiedAt &&
          listEquals(accentPaletteHex, other.accentPaletteHex);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        fontFamily,
        scaffoldBgHex,
        cardBgHex,
        cardBorderHex,
        textPrimaryHex,
        textSecondaryHex,
        isBuiltIn,
        lastModifiedAt,
        Object.hashAll(accentPaletteHex),
      );
}
