# Deixis icon

The shipped icon is `Deixis/AppIcon.icon` (Icon Composer package; Xcode composes it for macOS 26 and the
`AppIcon.appiconset` PNGs are the macOS 15 fallback). This folder holds the tools that regenerate it.

- `layers.swift` draws the flat 1024 pt layers: the disc (glass layer) and the two brackets.
  Args: output dir, then `disc,rect,stroke,arm` fractions. Shipped values: `0.616,1.10,0.016,0.17`.
- `glow.swift` draws the soft center light. `tint.swift` recolors the disc.
- `sheet.swift`, `compare.swift`, `icns.swift` build contact sheets for review.
- Render any package through Apple's engine (same one macOS 26 uses):
  `"/Applications/Xcode.app/Contents/Applications/Icon Composer.app/Contents/Executables/ictool" Deixis/AppIcon.icon --export-image --output-file out.png --platform macOS --rendition Default --width 1024 --height 1024 --scale 1`
  Renditions: `Default`, `Dark`, `TintedLight`, `TintedDark`, `ClearLight`, `ClearDark`.
- `renders/` holds the current icon at 1024 and 512, light and dark, for the site and the README.

Decisions (Sep 13, 2026): glass disc at 18 percent opacity, glow at 10, brackets at 55 percent label color with a
10 percent gap to the disc. No dot, no element, no overlap, no color: every added element read as noise.
