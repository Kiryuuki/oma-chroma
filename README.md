# OmaChroma

Desktop themes and cursor manager, downloader, and automated scheduler for Omarchy Quattro on Hyprland.

![OmaChroma Preview](assets/preview.png)

## Overview

OmaChroma brings a complete styling hub to the Omarchy Quattro shell:
* **Installed Themes**: Live wallpaper previews, color palette displays, and wallpaper count indicators with 1-click theme switching.
* **Installed Cursors & Size Slider**: Browse installed cursor themes and adjust cursor sizes dynamically across Hyprland and GTK.
* **Styling Randomizer**: Selectively pool favorite themes and cursor packs to roll random styling combos on demand.
* **Automated Background Scheduler**: Built-in cron daemon to auto-roll themes and cursors on custom intervals (Off, 1h, 12h, 24h, or custom hours).
* **Themes Store**: Real-time theme search, browsing, and installation across 88+ community themes with pre-cached thumbnails and palette displays. Supports adding, editing, and deleting custom Git repositories.
* **Cursors Store**: Discover curated cursor packages and manage custom release archive links (.tar.xz, .tar.gz, .zip) with inline source management.
* **Installed Manager**: View, inspect, and remove user-installed themes and cursor packs.
* **Wallpaper Store**: Browse and install 3000+ wallpapers with auto-generated color themes on demand. Each wallpaper includes palette previews, search, and pagination.

## Screenshots

| Themes Gallery | Cursors & Sizing |
|---|---|
| ![Themes](assets/preview_tab1_themes.png) | ![Cursors](assets/preview_tab2_cursors.png) |

| Styling Randomizer & Timer | Theme & Cursor Stores | Wallpaper Store |
|---|---|---|
| ![Randomizer](assets/preview_tab3_randomizer.png) | ![Store](assets/preview_tab4_store.png) | ![Wallpapers](assets/preview_tab6_wallpapers.png) |

## Features and Capabilities

* **Live Thumbnail Previews**: Real wallpaper rendering for local and community themes.
* **Real-Time Store Search**: Instant client-side search filtering by theme name, author, category, and description.
* **Dynamic Palette Swatches**: Parsed colors.toml palettes showing accent, background, foreground, red, and green highlights.
* **Non-Blocking Execution**: Asynchronous Python worker processes with atomic file updates.
* **Source Management**: Add multiple Git repositories or direct release archives simultaneously without immediate cloning.
* **Keyboard Navigation**: Full keycatcher integration for keyboard-driven navigation, tab switching, and instant rolls.

## Installation

Install directly using the Omarchy Plugin Manager:

```bash
omaplug install kiryuuki.oma-chroma
```

## Removal

To uninstall OmaChroma:

```bash
omaplug remove kiryuuki.oma-chroma
```

## Keyboard Shortcuts

| Key | Action |
|---|---|
| `1` | Switch to Themes Tab |
| `2` | Switch to Cursors Tab |
| `3` | Switch to Randomizer Tab |
| `4` | Switch to Themes Store Tab |
| `5` | Switch to Cursors Store Tab |
|| `6` | Switch to Installed Manager Tab |
|| `7` | Switch to Wallpaper Store Tab |
| `j` / `Down` | Move selection down |
| `k` / `Up` | Move selection up |
| `Enter` / `Space` | Apply selected theme or cursor / Trigger combo roll |
| `t` | Randomize Theme Only |
| `c` | Randomize Cursor Only |
| `w` | Cycle Next Wallpaper |
| `n` / `]` / `>` | Next Page |
| `p` / `[` / `<` | Previous Page |
| `r` | Refresh status and catalog |
| `Esc` | Close panel |

## Credits and Upstream Sources

OmaChroma integrates styling presets, themes, cursors, and artwork provided by open-source creators across the Linux and Omarchy communities:
* **Awesome Omarchy Themes**: Community repository catalog maintained by [aorumbayev](https://github.com/aorumbayev/awesome-omarchy).
* **Omarchy Themes Directory & Aether Palettes**: Curated wallpaper and palette library created by [bjarneo](https://bjarneo.github.io/omarchy-themes/).
* **Dracula Theme**: Official Dracula color adaptation for Omarchy by the [Dracula Theme Team](https://github.com/dracula/omarchy).
* **Catppuccin**: Theme and cursor ports by the [Catppuccin Organization](https://github.com/catppuccin/cursors).
* **Bibata Cursor Collection**: Open-source cursor packages designed by [AbdulKaiz (ful1e5)](https://github.com/ful1e5/Bibata_Cursor).
* **Nordzy Cursors**: Nordic-styled vector cursor set created by [Guillaume Boehm (alvatip)](https://github.com/guillaumeboehm/Nordzy-cursors).

All theme and cursor intellectual properties, licenses, trademarks, and wallpapers remain with their respective original creators and maintainers.

## License

PolyForm Noncommercial 1.0.0 (PolyForm-Noncommercial-1.0.0). See [LICENSE](LICENSE) for details.
