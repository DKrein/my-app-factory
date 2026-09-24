import 'package:flutter/material.dart';

/// The colors of one theme. Every color a screen draws comes from here.
///
/// A palette rides on [ThemeData] as a theme extension, so a widget reads it
/// with `context.palette` (or [FactoryPalette.of]) and never uses a literal
/// color. Changing the theme is then just passing another palette to
/// `factoryDarkTheme`; `MaterialApp` animates the change.
///
/// ## Adding a palette
///
/// 1. Declare a `static const` below with a new [id] (kebab or snake case,
///    never change it once published: it is what gets saved) and a [name].
/// 2. Fill the ten tokens. They are all dark: the app is used in bed.
///    Start from [capyNight] and keep the same roles, see each token.
/// 3. Add it to [all]. `test/palettes_test.dart` then checks its contrast
///    and fails with the pair that is too low.
/// 4. In the app, offer it in the theme picker and decide whether it is free
///    or Pro (`ProFeatures`).
///
/// Stars, icons and text never change color per palette except through
/// these tokens; the starfield image is white on every palette.
@immutable
class FactoryPalette extends ThemeExtension<FactoryPalette> {
  const FactoryPalette({
    required this.id,
    required this.name,
    required this.night,
    required this.surface,
    required this.surfaceElevated,
    required this.moon,
    required this.mist,
    required this.ink,
    required this.mutedInk,
    required this.outline,
    required this.activeSurface,
    required this.activeOutline,
  });

  /// Stable key saved in storage. Never rename it.
  final String id;

  /// What the picker shows.
  final String name;

  /// Screen background, the darkest color.
  final Color night;

  /// Cards and tiles resting on [night].
  final Color surface;

  /// Sheets, dialogs, chips and anything raised above [surface].
  final Color surfaceElevated;

  /// Secondary accent: primary buttons, links, the selected duration.
  final Color moon;

  /// Main accent: sound icons, sliders, filled action buttons. Text on top of
  /// it uses [night].
  final Color mist;

  /// Main text.
  final Color ink;

  /// Secondary text and quiet icons.
  final Color mutedInk;

  /// Borders of cards, chips and fields.
  final Color outline;

  /// Background of a selected or playing card.
  final Color activeSurface;

  /// Border of a selected or playing card.
  final Color activeOutline;

  /// White at 8%: it works over any of the dark backgrounds, so all palettes
  /// share it.
  Color get divider => const Color(0x14FFFFFF);

  /// The default palette, and the only free one in Sleepy Capy.
  static const capyNight = FactoryPalette(
    id: 'capy_night',
    name: 'Capy Night',
    night: Color(0xFF0B1020),
    surface: Color(0xFF151C33),
    surfaceElevated: Color(0xFF1D2745),
    moon: Color(0xFFAFC8FF),
    mist: Color(0xFF8ED9C7),
    ink: Color(0xFFF4F7FF),
    mutedInk: Color(0xFFB8C1D9),
    outline: Color(0xFF3B4768),
    activeSurface: Color(0xFF1E3550),
    activeOutline: Color(0xFF8EC5F5),
  );

  /// Warm amber with no blue at all, for the least light at night.
  static const amberEmber = FactoryPalette(
    id: 'amber_ember',
    name: 'Amber Ember',
    night: Color(0xFF130C07),
    surface: Color(0xFF1F150E),
    surfaceElevated: Color(0xFF2C1F15),
    moon: Color(0xFFF0C48A),
    mist: Color(0xFFE8A45C),
    ink: Color(0xFFF5E9D8),
    mutedInk: Color(0xFFC9B399),
    outline: Color(0xFF80603F),
    activeSurface: Color(0xFF3A2716),
    activeOutline: Color(0xFFE0A060),
  );

  static const mossForest = FactoryPalette(
    id: 'moss_forest',
    name: 'Moss Forest',
    night: Color(0xFF09130D),
    surface: Color(0xFF122019),
    surfaceElevated: Color(0xFF1B2F23),
    moon: Color(0xFFC8DC9E),
    mist: Color(0xFF8CCB92),
    ink: Color(0xFFEEF4E8),
    mutedInk: Color(0xFFB0C2AC),
    outline: Color(0xFF4A6A55),
    activeSurface: Color(0xFF203F2C),
    activeOutline: Color(0xFF9BD08A),
  );

  static const plumDusk = FactoryPalette(
    id: 'plum_dusk',
    name: 'Plum Dusk',
    night: Color(0xFF140A1B),
    surface: Color(0xFF211330),
    surfaceElevated: Color(0xFF2E1C42),
    moon: Color(0xFFE2BAF2),
    mist: Color(0xFFCFA2EE),
    ink: Color(0xFFF6EEFA),
    mutedInk: Color(0xFFC7B5D6),
    outline: Color(0xFF7A5C9C),
    activeSurface: Color(0xFF3B2358),
    activeOutline: Color(0xFFB98AE0),
  );

  /// Every palette, in the order a picker should list them.
  static const all = [capyNight, amberEmber, mossForest, plumDusk];

  static FactoryPalette byId(String? id) =>
      all.firstWhere((p) => p.id == id, orElse: () => capyNight);

  /// The palette of the current theme, [capyNight] if the theme has none.
  static FactoryPalette of(BuildContext context) =>
      Theme.of(context).extension<FactoryPalette>() ?? capyNight;

  @override
  FactoryPalette copyWith({
    String? id,
    String? name,
    Color? night,
    Color? surface,
    Color? surfaceElevated,
    Color? moon,
    Color? mist,
    Color? ink,
    Color? mutedInk,
    Color? outline,
    Color? activeSurface,
    Color? activeOutline,
  }) => FactoryPalette(
    id: id ?? this.id,
    name: name ?? this.name,
    night: night ?? this.night,
    surface: surface ?? this.surface,
    surfaceElevated: surfaceElevated ?? this.surfaceElevated,
    moon: moon ?? this.moon,
    mist: mist ?? this.mist,
    ink: ink ?? this.ink,
    mutedInk: mutedInk ?? this.mutedInk,
    outline: outline ?? this.outline,
    activeSurface: activeSurface ?? this.activeSurface,
    activeOutline: activeOutline ?? this.activeOutline,
  );

  @override
  FactoryPalette lerp(ThemeExtension<FactoryPalette>? other, double t) {
    if (other is! FactoryPalette) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return FactoryPalette(
      id: t < .5 ? id : other.id,
      name: t < .5 ? name : other.name,
      night: mix(night, other.night),
      surface: mix(surface, other.surface),
      surfaceElevated: mix(surfaceElevated, other.surfaceElevated),
      moon: mix(moon, other.moon),
      mist: mix(mist, other.mist),
      ink: mix(ink, other.ink),
      mutedInk: mix(mutedInk, other.mutedInk),
      outline: mix(outline, other.outline),
      activeSurface: mix(activeSurface, other.activeSurface),
      activeOutline: mix(activeOutline, other.activeOutline),
    );
  }
}

extension FactoryPaletteContext on BuildContext {
  /// Shorthand for [FactoryPalette.of].
  FactoryPalette get palette => FactoryPalette.of(this);
}
