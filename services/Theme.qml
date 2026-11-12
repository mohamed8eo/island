import QtQuick
import Quickshell.Io
import qs.Commons

// The island's colours, font and motion speed. By default the island is black
// with neutral, macOS-like text and greys, and only the accent comes from the
// Omarchy theme; with `followTheme` it takes the theme's background, text and
// status colours instead (Settings → General → Appearance).
Item {
  id: theme
  required property var settings
  required property string home

  readonly property string fontFamily: "monospace"
  // Text family for the island's surfaces: its own, Omarchy's (the menu font,
  // so `omarchy font set` and OMARCHY_MENU_FONT carry over), or a custom one.
  readonly property string pluginFont: "Adwaita Sans"
  readonly property string textFontFamily: {
    var mode = settings.textFontMode || "island"
    if (mode === "omarchy") return Style.font.menuFamily || Style.font.family || pluginFont
    var custom = String(settings.customFont || "").trim()
    if (mode === "custom" && custom) return custom
    return pluginFont
  }
  // One knob for every text size in the island: sizes are written as the
  // value at 1.0 and passed through px().
  readonly property real textScale: settings.textScale > 0 ? settings.textScale : 1
  function px(size) { return Math.max(1, Math.round(size * textScale)) }
  // The text sizes, named as macOS's text styles. Glyphs and the few big
  // numerals are sized on their own with px().
  readonly property var size: ({
    largeTitle: px(26), title1: px(22), title2: px(17), title3: px(15),
    body: px(13), callout: px(12), subheadline: px(11), footnote: px(10)
  })
  // Letter spacing for the island's own font (Adwaita Sans, drawn from
  // Inter): Inter's size-based tracking, a touch looser below 12px and
  // tighter as text grows, as macOS does. Other fonts keep their spacing.
  function tracking(family, size) {
    if (family !== pluginFont || !(size > 0)) return 0
    return size * (-0.0223 + 0.185 * Math.exp(-0.1745 * size))
  }
  // Follow the active Omarchy theme: the island takes the theme's background
  // and foreground instead of its fixed black-and-neutral look, and its
  // status colours come from the theme's own palette. Omarchy's Color
  // singleton is reloaded live when a theme is applied, so these update
  // without a shell restart. Off by default: the island stays black, with
  // only the accent from the theme.
  readonly property bool followTheme: !!settings.followTheme
  readonly property color background: followTheme ? Color.background : "#000000"
  // The island's text is a neutral near-white unless it follows the theme,
  // whose foreground is often tinted (and dark on light themes); every grey
  // below is derived from it, so following a theme tints them all.
  readonly property color text: followTheme ? Color.foreground : "#e6e6e6"
  // Secondary text and glyphs: the text colour at 60%, as macOS's secondary
  // label. It stays neutral when the island is black, and takes the theme's
  // tint when following one.
  readonly property color muted: secondary
  readonly property color accent: Color.accent
  // Status, colourful live activities and charts: Apple's dark-mode system
  // colours by default, so they keep their meaning whatever the Omarchy
  // theme, or the theme's palette when following it.
  readonly property var system: followTheme ? themedSystem : defaultSystem
  readonly property var defaultSystem: ({
    red: "#ff453a", orange: "#ff9f0a", yellow: "#ffd60a", green: "#30d158", cyan: "#64d2ff",
    blue: "#0a84ff", indigo: "#5e5ce6", purple: "#bf5af2", gray: "#8e8e93"
  })
  // The theme's palette, mapped onto the island's system roles. Both naming
  // styles in colors.toml are covered (`red`, `green`, … and `color1`,
  // `color2`, …), with Omarchy's foundational roles as the last resort.
  readonly property var themedSystem: ({
    red: palette.red || palette.color1 || Color.urgent,
    orange: palette.orange || palette.bright_yellow || palette.yellow || palette.color3 || Color.urgent,
    yellow: palette.yellow || palette.bright_yellow || palette.color3 || Color.foreground,
    green: palette.green || palette.bright_green || palette.color2 || Color.accent,
    cyan: palette.cyan || palette.bright_cyan || palette.color6 || Color.accent,
    blue: palette.blue || palette.bright_blue || palette.color4 || Color.accent,
    indigo: palette.magenta || palette.bright_magenta || palette.color5 || Color.accent,
    purple: palette.bright_magenta || palette.magenta || palette.color5 || Color.accent,
    gray: palette.muted || palette.color8 || Color.muted
  })
  // colors.toml as "key -> #rrggbb", so the theme's palette can be used for
  // more than the four roles Omarchy's Color exposes.
  property var palette: ({})
  function parseColors(raw) {
    var out = ({})
    var lines = String(raw || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var match = lines[i].match(/^\s*([A-Za-z0-9_-]+)\s*=\s*["']?(#[0-9A-Fa-f]{6})/)
      if (match) out[match[1]] = match[2]
    }
    return out
  }
  readonly property color accentText: contrastOn(Color.accent)
  readonly property color urgent: Color.urgent
  readonly property color surface: card
  // The island's greys: a few text-tint levels every view shares, so a card,
  // a hover or a divider is the same grey everywhere. `fill()` is see-through
  // (for hovers and edges laid over anything); `solid()` is that grey on the
  // black island. Accent tints follow the same idea with `accentFill()`.
  readonly property var greys: ({ quiet: 0.05, subtle: 0.08, raised: 0.12, strong: 0.16, stronger: 0.22 })
  readonly property var accentTints: ({ soft: 0.18, medium: 0.3, ring: 0.5 })
  function fill(level) { return withAlpha(text, greys[level]) }
  function solid(level) { return Qt.tint(background, fill(level)) }
  function accentFill(level) { return withAlpha(accent, accentTints[level]) }
  readonly property color secondary: Qt.tint(background, withAlpha(text, 0.6))
  // Neutral (not theme-tinted) grey for placeholders and the search glyph.
  readonly property color placeholder: Qt.tint(background, withAlpha(text, 0.38))
  readonly property color card: solid("subtle")
  readonly property color tile: solid("raised")
  readonly property color well: solid("strong")
  readonly property color wellHover: solid("stronger")
  readonly property color hairline: fill("subtle")
  // Corner radii, so a corner is the same size everywhere. A box sitting
  // directly in an open view (a card, a group, a list) is concentric with
  // the island: its 30 radius minus the usual 16 padding.
  readonly property var radii: ({ small: 6, medium: 8, large: 10, card: 14 })
  readonly property real motionScale: settings.motionScale > 0 ? settings.motionScale : 1.5
  // Motion roles share one cadence at every user-selected speed. Curves end
  // with a soft landing; geometry stays inside its bounds, except the
  // island itself, which swings a touch past its size as it grows
  // (morphBounce) and dips a touch under it as a pill shrinks back
  // (shrugBounce).
  readonly property var motionDurations: ({
    press: 65, quick: 110, standard: 170, expressive: 220,
    morph: 240, collapse: 190, fade: 110, exit: 90,
    data: 330
  })
  readonly property int contentRevealDelay: Math.round(45 * motionScale)
  // How far the island's height trails its width as it grows (and the width
  // trails the height as it shrinks), so it morphs as one shape.
  readonly property int morphLag: Math.round(28 * motionScale)
  readonly property real morphBounce: 0.2
  // How far a pill dips under its resting size as it shrinks back.
  readonly property real shrugBounce: 0.3
  // Any other timing (a stagger step, an offset after contentRevealDelay, a
  // pulse) at the user's motion speed, given at Fast (1×) like the table
  // above, so it keeps its rhythm with the rest at every speed.
  function scaled(ms) { return Math.round(ms * motionScale) }
  function motionDuration(pace) {
    return Math.round((motionDurations[pace] || motionDurations.standard) * motionScale)
  }
  function motionCurve(curve) {
    if (curve === "morph") return [0.22, 0.8, 0.24, 1, 1, 1]
    if (curve === "fade") return [0.2, 0, 0.2, 1, 1, 1]
    if (curve === "exit") return [0.4, 0, 1, 1, 1, 1]
    return [0.16, 1, 0.3, 1, 1, 1]
  }
  // The current Omarchy theme's name, for the theme and wallpaper switchers.
  property string name: ""

  function withAlpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
  function luminance(x) { return 0.2126 * x.r + 0.7152 * x.g + 0.0722 * x.b }
  function contrastOn(c) {
    var l = luminance(c)
    return Math.abs(l - luminance(background)) > Math.abs(l - luminance(text)) ? background : text
  }

  FileView {
    path: theme.home + "/.local/state/omarchy/current/theme.name"
    watchChanges: true
    printErrors: false
    onLoaded: theme.name = text().trim()
    onFileChanged: reload()
  }
  // The theme's colors.toml, re-read whenever Omarchy writes a new
  // theme.generation (it does at the end of every theme switch), so the
  // island's palette follows a theme change without a restart.
  FileView {
    id: colorsFile
    path: theme.home + "/.local/state/omarchy/current/theme/colors.toml"
    watchChanges: false
    printErrors: false
    onLoaded: theme.palette = theme.parseColors(text())
    onLoadFailed: theme.palette = ({})
  }
  FileView {
    id: generationFile
    path: theme.home + "/.local/state/omarchy/current/theme.generation"
    watchChanges: true
    printErrors: false
    onLoaded: colorsFile.reload()
    onFileChanged: reload()
  }
}
