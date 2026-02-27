pragma Singleton
import QtQuick

QtObject {
    // ── Aurora Dark Palette (Catppuccin Mocha) ──
    readonly property color base:       "#1e1e2e"
    readonly property color mantle:     "#181825"
    readonly property color crust:      "#11111b"
    readonly property color surface0:   "#313244"
    readonly property color surface1:   "#45475a"
    readonly property color surface2:   "#585b70"
    readonly property color overlay0:   "#6c7086"
    readonly property color overlay1:   "#7f849c"
    readonly property color text:       "#cdd6f4"
    readonly property color subtext0:   "#a6adc8"
    readonly property color subtext1:   "#bac2de"

    // Accent colors
    readonly property color accent:     "#cba6f7"   // Mauve
    readonly property color accentAlt:  "#89b4fa"   // Blue
    readonly property color teal:       "#94e2d5"
    readonly property color green:      "#a6e3a1"
    readonly property color peach:      "#fab387"
    readonly property color red:        "#f38ba8"
    readonly property color yellow:     "#f9e2af"
    readonly property color pink:       "#f5c2e7"
    readonly property color lavender:   "#b4befe"
    readonly property color sky:        "#89dceb"

    // Glassmorphism
    readonly property color panelBg:     Qt.rgba(0.07, 0.07, 0.11, 0.92)
    readonly property color panelBorder: Qt.rgba(0.796, 0.651, 0.969, 0.18)
    readonly property color widgetBg:    Qt.rgba(0.09, 0.09, 0.14, 0.88)
    readonly property color widgetBorder:Qt.rgba(0.796, 0.651, 0.969, 0.12)
    readonly property color popupBg:     Qt.rgba(0.07, 0.07, 0.11, 0.94)

    // Typography — JetBrainsMono Nerd Font everywhere
    readonly property string fontFamily: "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
    readonly property string monoFont:   "JetBrainsMono Nerd Font, JetBrains Mono, monospace"
    readonly property int fontTiny:     10
    readonly property int fontSmall:    12
    readonly property int fontNormal:   14
    readonly property int fontMedium:   16
    readonly property int fontLarge:    20
    readonly property int fontXL:       28
    readonly property int fontXXL:      52

    // Layout
    readonly property int radiusSmall:  8
    readonly property int radiusMedium: 14
    readonly property int radiusLarge:  18
    readonly property int radiusXL:     24
    readonly property int spacing:      10
    readonly property int spacingSmall: 6
    readonly property int spacingLarge: 18

    // Bar
    readonly property int barHeight:    48
    readonly property int barMargin:    4

    // Animation durations
    readonly property int animFast:     150
    readonly property int animNormal:   250
    readonly property int animSlow:     400
    readonly property int animSpring:   500

    // Shadows
    readonly property color shadowColor: Qt.rgba(0, 0, 0, 0.5)

    // Widget
    readonly property int widgetPadding: 18

    // Wallpaper — mutable, changed at runtime by WallpaperSelector
    property string wallpaperPath: "/home/amrit/Pictures/wallpapers/wallpaper.webp"
}
