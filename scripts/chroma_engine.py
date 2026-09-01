#!/usr/bin/env python3
"""
OmaChroma Engine: Complete Themes & Cursors Suite for Omarchy Quattro.
Features:
- Live wallpaper thumbnails and wallpaper counts for local themes.
- Daily caching of 88 verified online community themes + custom user theme & cursor sources with full Add/Edit/Delete source management.
- Disk thumbnail caching (~/.cache/omarchy-chroma/thumbnails/) for instant theme store rendering.
- Automated Background Timer Daemon / Cron Service (Off, 1h, 12h, 24h, or Custom Hours).
- Dedicated Custom Source Management for both Themes Store and Cursors Store.
- 0600 descriptor safety and unprivileged execution.
"""

import argparse
import hashlib
import json
import os
from pathlib import Path
import random
import re
import shutil
import stat
import subprocess
import sys
import tempfile
import time
import urllib.request
import tarfile
import zipfile

STATE_DIR = Path.home() / ".local" / "state" / "omarchy" / "chroma"
STATE_FILE = STATE_DIR / "status.json"
CONFIG_FILE = STATE_DIR / "config.json"
CACHE_DIR = Path.home() / ".cache" / "omarchy-chroma"
THUMBNAIL_DIR = CACHE_DIR / "thumbnails"
ONLINE_THEMES_CACHE = CACHE_DIR / "online_themes.json"
MAX_STATE_BYTES = 5 * 1024 * 1024  # 5 MB
CACHE_TTL = 24 * 3600  # 24 hours

REPO_BACKGROUND_MAP = {
    "JJDizz1L/aetheria": "https://raw.githubusercontent.com/JJDizz1L/aetheria/omarchy-aetheria-theme/backgrounds/aetheria-1-4k%40.jpg",
    "dracula/omarchy": "https://raw.githubusercontent.com/dracula/omarchy/main/backgrounds/base.png",
    "999Gabriel/F1-omarchy": "https://raw.githubusercontent.com/999Gabriel/F1-omarchy/main/preview.png",
    "vyrx-dev/omarchy-aamis-theme": "https://raw.githubusercontent.com/vyrx-dev/omarchy-aamis-theme/master/backgrounds/wallhaven-mdjrqy.jpg",
    "rblalock/omarchy-agentuity.theme": "https://raw.githubusercontent.com/rblalock/omarchy-agentuity.theme/master/backgrounds/BG2.jpg",
    "Grenish/omarchy-akane-theme": "https://raw.githubusercontent.com/Grenish/omarchy-akane-theme/main/backgrounds/1-akane.jpg",
    "guilhermetk/omarchy-all-hallows-eve-theme": "https://raw.githubusercontent.com/guilhermetk/omarchy-all-hallows-eve-theme/master/backgrounds/1-background.png",
    "tahfizhabib/omarchy-amberbyte-theme": "https://raw.githubusercontent.com/tahfizhabib/omarchy-amberbyte-theme/main/backgrounds/1.png",
    "j4v3l/omarchy-anonymous-theme": "https://raw.githubusercontent.com/j4v3l/omarchy-anonymous-theme/main/backgrounds/01-bg-Anonymous.png",
    "vale-c/omarchy-arc-blueberry": "https://raw.githubusercontent.com/vale-c/omarchy-arc-blueberry/main/backgrounds/1.png",
    "CyphrRiot/omarchy-archriot-theme": "https://raw.githubusercontent.com/CyphrRiot/omarchy-archriot-theme/main/backgrounds/1-archriot.jpg",
    "bjarneo/omarchy-ash-theme": "https://raw.githubusercontent.com/bjarneo/omarchy-ash-theme/main/backgrounds/1-ash.jpg",
    "bjarneo/omarchy-aura-theme": "https://raw.githubusercontent.com/bjarneo/omarchy-aura-theme/main/backgrounds/1.png",
    "abhijeet-swami/omarchy-ayaka-theme": "https://raw.githubusercontent.com/abhijeet-swami/omarchy-ayaka-theme/main/backgrounds/a9.jpg",
    "fdidron/omarchy-ayu-dark-theme": "https://raw.githubusercontent.com/fdidron/omarchy-ayu-dark-theme/main/backgrounds/1-Nocturne-of-Steel-and-Glass.png",
    "fdidron/omarchy-ayumirage": "https://raw.githubusercontent.com/fdidron/omarchy-ayu-mirage-theme/main/backgrounds/1-Nocturne-of-Steel-and-Glass.png",
    "Hydradevx/omarchy-azure-glow-theme": "https://raw.githubusercontent.com/Hydradevx/omarchy-azure-glow-theme/main/backgrounds/City-Rainy-Night.png",
    "HANCORE-linux/omarchy-batou-theme": "https://raw.githubusercontent.com/HANCORE-linux/omarchy-batou-theme/main/backgrounds/BG1-b.png",
    "somerocketeer/omarchy-bauhaus-theme": "https://raw.githubusercontent.com/mwaltzer/omarchy-bauhaus-theme/main/backgrounds/Bauhaus01.jpg",
    "HANCORE-linux/omarchy-blackgold-theme": "https://raw.githubusercontent.com/HANCORE-linux/omarchy-blackgold-theme/V2-Blackgold/backgrounds/BG1-2.jpg",
    "HANCORE-linux/omarchy-blackmoney-theme": "https://raw.githubusercontent.com/HANCORE-linux/omarchy-blackmoney-theme/main/backgrounds/BG1.jpg",
    "HANCORE-linux/omarchy-blackturq-theme": "https://raw.githubusercontent.com/HANCORE-linux/omarchy-blackturq-theme/main/backgrounds/BG1.jpg",
    "hipsterusername/omarchy-blueridge-dark-theme": "https://raw.githubusercontent.com/hipsterusername/omarchy-blueridge-dark-theme/main/backgrounds/c6bf4dbd-d4ad-4d1d-96a7-51bf5202ab08.png",
    "KidDogDad/omarchy-catppuccin-mocha-theme": "https://raw.githubusercontent.com/KidDogDad/omarchy-catppuccin-mocha-theme/main/backgrounds/1-shaded-landscape.jpg",
    "hoblin/omarchy-cobalt2-theme": "https://raw.githubusercontent.com/hoblin/omarchy-cobalt2-theme/main/backgrounds/01_a_car_on_a_road_with_orange_clouds_in_the_sky.jpg",
    "knappkevin/omarchy-crimson-gold-theme": "https://raw.githubusercontent.com/knappkevin/omarchy-crimson-gold-theme/main/backgrounds/1-crimson-gold.png",
    "jbnunn/omarchy-delorean-theme": "https://raw.githubusercontent.com/jbnunn/omarchy-delorean-theme/main/backgrounds/1-DeLorean.png",
    "AX200M/omarchy-doom-theme": "https://raw.githubusercontent.com/AX200M/omarchy-doom-theme/main/backgrounds/a_colorful_mask_on_a_black_background.jpg",
    "catlee/omarchy-dracula-theme": "https://raw.githubusercontent.com/catlee/omarchy-dracula-theme/main/backgrounds/base.png",
    "bjarneo/omarchy-elysian-theme": "https://raw.githubusercontent.com/bjarneo/omarchy-elysian-theme/main/backgrounds/1-steph-johnstone.jpg",
    "Swarnim114/omarchy-everblush-theme": "https://raw.githubusercontent.com/Swarnim114/omarchy-everblush-theme/main/backgrounds/everblush-1.jpg",
    "celsobenedetti/omarchy-evergarden": "https://raw.githubusercontent.com/celsobenedetti/omarchy-evergarden/master/backgrounds/1-evergarden.png",
    "TyRichards/omarchy-felix-theme": "https://raw.githubusercontent.com/TyRichards/omarchy-felix-theme/main/backgrounds/00-black.png",
    "mattbbia/fire-and-shadow": "https://raw.githubusercontent.com/mattbbia/fire-and-shadow/main/backgrounds/cottage-on-fire-at-night-between-1785-1793.jpg",
    "bjarneo/omarchy-fireside-theme": "https://raw.githubusercontent.com/bjarneo/omarchy-fireside-theme/main/backgrounds/1.png",
    "bjarneo/omarchy-firesky-theme": "https://raw.githubusercontent.com/bjarneo/omarchy-firesky-theme/main/backgrounds/1.png",
    "euandeas/omarchy-flexoki-dark-theme": "https://raw.githubusercontent.com/euandeas/omarchy-flexoki-dark-theme/main/backgrounds/flexoki-dark-omarchy.png",
    "euandeas/omarchy-flexoki-light-theme": "https://raw.githubusercontent.com/euandeas/omarchy-flexoki-light-theme/main/backgrounds/flexoki-light-omarchy.png",
    "abhijeet-swami/omarchy-forest-green-theme": "https://raw.githubusercontent.com/abhijeet-swami/omarchy-forest-green-theme/main/backgrounds/1-FG.jpg",
    "bjarneo/omarchy-frost-theme": "https://raw.githubusercontent.com/bjarneo/omarchy-frost-theme/main/backgrounds/1.jpg"
}

PALETTE_PRESETS = [
    { "accent": "#bb9af7", "background": "#1a1b26", "foreground": "#c0caf5", "green": "#73daca", "red": "#f7768e" },
    { "accent": "#bd93f9", "background": "#282a36", "foreground": "#f8f8f2", "green": "#50fa7b", "red": "#ff5555" },
    { "accent": "#a87cd9", "background": "#1f1d2e", "foreground": "#e0def4", "green": "#9ccfd8", "red": "#eb6f92" },
    { "accent": "#e5c07b", "background": "#141414", "foreground": "#dcdfe4", "green": "#98c379", "red": "#e06c75" },
    { "accent": "#4ec9b0", "background": "#181a1f", "foreground": "#abb2bf", "green": "#98c379", "red": "#e06c75" },
    { "accent": "#ffc600", "background": "#193549", "foreground": "#ffffff", "green": "#3ad900", "red": "#ff005b" },
    { "accent": "#73c48f", "background": "#232a2e", "foreground": "#d5d6c8", "green": "#6bb07e", "red": "#e67e80" },
    { "accent": "#89dceb", "background": "#181825", "foreground": "#cdd6f4", "green": "#a6e3a1", "red": "#f38ba8" },
    { "accent": "#f59e0b", "background": "#1e1e2e", "foreground": "#f8fafc", "green": "#10b981", "red": "#ef4444" },
    { "accent": "#f97316", "background": "#1a1626", "foreground": "#e2e8f0", "green": "#4ade80", "red": "#f43f5e" },
    { "accent": "#38bdf8", "background": "#0f172a", "foreground": "#f1f5f9", "green": "#34d399", "red": "#fb7185" },
    { "accent": "#60a5fa", "background": "#1e293b", "foreground": "#f8fafc", "green": "#4ade80", "red": "#f87171" }
]

RAW_COMMUNITY_THEMES = [
    ("aetheria", "https://github.com/JJDizz1L/aetheria", "Ethereal and modern theme with balanced aesthetics.", "Modern"),
    ("dracula/omarchy", "https://github.com/dracula/omarchy", "Official Dracula theme for Omarchy.", "Gothic"),
    ("F1-omarchy", "https://github.com/999Gabriel/F1-omarchy", "Formula 1 inspired Omarchy layout with racing telemetry flair.", "Racing"),
    ("omarchy-aamis-theme", "https://github.com/vyrx-dev/omarchy-aamis-theme", "Near‑black canvas with creamy text.", "Minimal"),
    ("omarchy-agentuity.theme", "https://github.com/rblalock/omarchy-agentuity.theme", "Agentuity-inspired theme with professional color palette.", "Pro"),
    ("omarchy-akane-theme", "https://github.com/Grenish/omarchy-akane-theme", "Akane theme with Japanese-inspired colors.", "Anime"),
    ("omarchy-all-hallows-eve-theme", "https://github.com/guilhermetk/omarchy-all-hallows-eve-theme", "Dark Halloween-inspired theme with spooky aesthetics.", "Seasonal"),
    ("omarchy-amberbyte-theme", "https://github.com/tahfizhabib/omarchy-amberbyte-theme", "Modern, animated, and minimal theme with amber accents.", "Amber"),
    ("omarchy-anonymous-theme", "https://github.com/j4v3l/omarchy-anonymous-theme", "Minimalist monochrome modern theme.", "Monochrome"),
    ("omarchy-arc-blueberry", "https://github.com/vale-c/omarchy-arc-blueberry", "Arc Blueberry inspired colors tailored for Omarchy.", "Arc"),
    ("omarchy-archriot-theme", "https://github.com/CyphrRiot/omarchy-archriot-theme", "ArchRiot theme for Omarchy by CyphrRiot.", "Cyberpunk"),
    ("omarchy-ash-theme", "https://github.com/bjarneo/omarchy-ash-theme", "Subtle ash-gray color scheme.", "Minimal"),
    ("omarchy-aura-theme", "https://github.com/bjarneo/omarchy-aura-theme", "Aura theme providing visually appealing configuration set.", "Glow"),
    ("omarchy-ayaka-theme", "https://github.com/abhijeet-swami/omarchy-ayaka-theme", "Minimalist theme with glass-like blur effects and vibrant accents.", "Glass"),
    ("omarchy-ayu-dark-theme", "https://github.com/fdidron/omarchy-ayu-dark-theme", "Ayu Dark color scheme adaptation.", "Dark"),
    ("omarchy-ayu-mirage-theme", "https://github.com/fdidron/omarchy-ayumirage", "Ayu Mirage color scheme adaptation with balanced contrast.", "Mirage"),
    ("omarchy-azure-glow-theme", "https://github.com/Hydradevx/omarchy-azure-glow-theme", "Azure blue theme with glowing accents.", "Neon"),
    ("omarchy-batou-theme", "https://github.com/HANCORE-linux/omarchy-batou-theme", "Moody theme inspired by Batou's car and opening scene aesthetics.", "Cyber"),
    ("omarchy-bauhaus-theme", "https://github.com/somerocketeer/omarchy-bauhaus-theme", "Minimalist theme inspired by Bauhaus design principles.", "Retro"),
    ("omarchy-blackgold-theme", "https://github.com/HANCORE-linux/omarchy-blackgold-theme", "Sleek black-and-gold theme with luxurious aesthetics.", "Luxury"),
    ("omarchy-blackmoney-theme", "https://github.com/HANCORE-linux/omarchy-blackmoney-theme", "Bold midnight theme with rich green-gold accents.", "Executive"),
    ("omarchy-blackturq-theme", "https://github.com/HANCORE-linux/omarchy-blackturq-theme", "Black turquoise theme based on Evo80 keyboard color pattern.", "Keyboard"),
    ("omarchy-blueridge-dark-theme", "https://github.com/hipsterusername/omarchy-blueridge-dark-theme", "Dark theme inspired by mountain ridge aesthetics.", "Mountain"),
    ("omarchy-catppuccin-mocha-theme", "https://github.com/KidDogDad/omarchy-catppuccin-mocha-theme", "Catppuccin Mocha theme for Omarchy.", "Pastel"),
    ("omarchy-cobalt2-theme", "https://github.com/hoblin/omarchy-cobalt2-theme", "Cobalt2 theme inspired by the iconic VSCode theme.", "Coding"),
    ("omarchy-crimson-gold-theme", "https://github.com/knappkevin/omarchy-crimson-gold-theme", "Luxurious crimson and gold color combination.", "Luxury"),
    ("omarchy-delorean-theme", "https://github.com/jbnunn/omarchy-delorean-theme", "Retro-inspired time traveler's theme.", "Retro"),
    ("omarchy-doom-theme", "https://github.com/AX200M/omarchy-doom-theme", "Material theme inspired by MF DOOM wallpaper.", "HipHop"),
    ("omarchy-dracula-theme", "https://github.com/catlee/omarchy-dracula-theme", "Popular Dracula theme adaptation.", "Dark"),
    ("omarchy-elysian-theme", "https://github.com/bjarneo/omarchy-elysian-theme", "Mythical forest theme with golden-green light and high contrast.", "Nature"),
    ("omarchy-everblush-theme", "https://github.com/Swarnim114/omarchy-everblush-theme", "Everblush color scheme adaptation.", "Cozy"),
    ("omarchy-evergarden-theme", "https://github.com/celsobenedetti/omarchy-evergarden", "Evergarden theme with lush greens and soft pastels.", "Forest"),
    ("omarchy-felix-theme", "https://github.com/TyRichards/omarchy-felix-theme", "Clean theme with balanced colors and modern design.", "Clean"),
    ("omarchy-fire-and-shadow-theme", "https://github.com/mattbbia/fire-and-shadow", "A moody, somber theme based on the paintings of Joseph Wright.", "Art"),
    ("omarchy-fireside-theme", "https://github.com/bjarneo/omarchy-fireside-theme", "Warm, cozy theme inspired by the gentle glow of a fire.", "Warm"),
    ("omarchy-firesky-theme", "https://github.com/bjarneo/omarchy-firesky-theme", "Fire-lit sky inspired theme for deep focus.", "Sky"),
    ("omarchy-flexoki-dark-theme", "https://github.com/euandeas/omarchy-flexoki-dark-theme", "Flexoki color palette adaptation.", "Inky"),
    ("omarchy-flexoki-light-theme", "https://github.com/euandeas/omarchy-flexoki-light-theme", "Light version of Flexoki color palette.", "Light"),
    ("omarchy-forest-green-theme", "https://github.com/abhijeet-swami/omarchy-forest-green-theme", "Nature-inspired forest green color scheme.", "Green"),
    ("omarchy-frost-theme", "https://github.com/bjarneo/omarchy-frost-theme", "Simple, elegant theme inspired by frost patterns.", "Arctic"),
    ("omarchy-frutiger-aero", "https://github.com/celsobenedetti/omarchy-frutiger-aero", "Frutiger Aero theme with liquid glass aesthetics.", "Aero"),
    ("omarchy-futurism-theme", "https://github.com/bjarneo/omarchy-futurism-theme", "Futuristic theme with modern aesthetics.", "Future"),
    ("omarchy-gold-rush-theme", "https://github.com/HANCORE-linux/omarchy-goldrush-theme", "Luxurious gold-themed color scheme.", "Gold"),
    ("omarchy-green-garden-theme", "https://github.com/bjarneo/omarchy-green-garden-theme", "Fresh and calming theme inspired by nature.", "Garden"),
    ("omarchy-harbor-theme", "https://github.com/bjarneo/omarchy-harbor-theme", "Calm, paper-light color scheme with cool ink accents.", "Nordic"),
    ("omarchy-harbordark-theme", "https://github.com/bjarneo/omarchy-harbordark-theme", "Dark version of Harbor theme with deep tones.", "Harbor"),
    ("omarchy-inkypinky-theme", "https://github.com/bjarneo/omarchy-inkypinky-theme", "Bold meets blush in a swirl of creative elegance.", "Pink"),
    ("omarchy-kimiko-theme", "https://github.com/bjarneo/omarchy-kimiko-theme", "Elegant theme with Japanese-inspired aesthetics.", "Japan"),
    ("omarchy-mars-theme", "https://github.com/bjarneo/omarchy-mars-theme", "Mars-inspired red theme.", "Space"),
    ("omarchy-matte-black", "https://github.com/bjarneo/omarchy-matte-black", "Sleek matte black theme for minimalists.", "OLED"),
    ("omarchy-midnight-theme", "https://github.com/bjarneo/omarchy-midnight-theme", "Dark midnight theme optimized for OLED displays.", "OLED"),
    ("omarchy-milkmatcha-light-theme", "https://github.com/bjarneo/omarchy-milkmatcha-light-theme", "Light theme with soft matcha green and creamy colors.", "Matcha"),
    ("omarchy-monochrome-theme", "https://github.com/bjarneo/omarchy-monochrome-theme", "Clean monochrome design.", "Mono"),
    ("omarchy-monokai-theme", "https://github.com/bjarneo/omarchy-monokai-theme", "High-contrast Monokai Pro inspired variant.", "Coding"),
    ("omarchy-moodpeak-theme", "https://github.com/bjarneo/omarchy-moodpeak-theme", "Mood-lifting theme designed for peak focus.", "Vibrant"),
    ("omarchy-nagai-twilight-theme", "https://github.com/bjarneo/omarchy-nagai-twilight-theme", "Twilight-inspired theme with elegant transitions.", "Dusk"),
    ("omarchy-nes-theme", "https://github.com/bjarneo/omarchy-nes-theme", "Retro NES theme with nostalgic gaming aesthetics.", "Retro"),
    ("omarchy-one-dark-pro-theme", "https://github.com/bjarneo/omarchy-one-dark-pro-theme", "One Dark Pro color scheme adaptation.", "Pro"),
    ("omarchy-osaka-jade-theme", "https://github.com/bjarneo/omarchy-osaka-jade-theme", "Elegant jade-colored theme inspired by Osaka aesthetics.", "Jade"),
    ("omarchy-pissarro-theme", "https://github.com/bjarneo/omarchy-pissarro-theme", "A light theme inspired by Camille Pissarro.", "Art"),
    ("omarchy-pulsar-theme", "https://github.com/bjarneo/omarchy-pulsar-theme", "Vibrant, cosmic-inspired dark theme for Omarchy.", "Cosmic"),
    ("omarchy-purplewave-theme", "https://github.com/bjarneo/omarchy-purplewave-theme", "Purple wave-inspired theme with elegant purple tones.", "Purple"),
    ("omarchy-retro-fallout-theme", "https://github.com/bjarneo/omarchy-retro-fallout-theme", "Post-apocalyptic theme with Fallout-themed styling.", "Fallout"),
    ("omarchy-retropc-theme", "https://github.com/bjarneo/omarchy-retropc-theme", "Nostalgic retro PC theme with vintage computing aesthetics.", "Vintage"),
    ("omarchy-rose-pine", "https://github.com/rose-pine/omarchy", "Rose Pine theme for Omarchy.", "Pastel"),
    ("omarchy-sakura-theme", "https://github.com/bjarneo/omarchy-sakura-theme", "Elegant high-contrast cherry blossom theme.", "Sakura"),
    ("omarchy-sapphire-theme", "https://github.com/bjarneo/omarchy-sapphire-theme", "Vivid blue theme with rich accents.", "Blue"),
    ("omarchy-serenity-theme", "https://github.com/bjarneo/omarchy-serenity-theme", "Serenity theme with calm and peaceful color scheme.", "Peaceful"),
    ("omarchy-shadesofjade-theme", "https://github.com/bjarneo/omarchy-shadesofjade-theme", "Serene green-toned theme.", "Jade"),
    ("omarchy-snow-theme", "https://github.com/bjarneo/omarchy-snow-theme", "Snow theme with clean winter-inspired aesthetics.", "Winter"),
    ("omarchy-solarized-light-theme", "https://github.com/bjarneo/omarchy-solarized-light-theme", "Light version of Solarized color scheme.", "Light"),
    ("omarchy-solarized-osaka-theme", "https://github.com/bjarneo/omarchy-solarized-osaka-theme", "Solarized theme with Osaka-inspired modifications.", "Osaka"),
    ("omarchy-solarized-theme", "https://github.com/bjarneo/omarchy-solarized-theme", "Classic Solarized color scheme adaptation.", "Solarized"),
    ("omarchy-space-monkey-theme", "https://github.com/bjarneo/omarchy-space-monkey-theme", "Space-inspired theme with cosmic elements.", "Cosmic"),
    ("omarchy-spectra-theme", "https://github.com/bjarneo/omarchy-spectra-theme", "Blur and transparency theme that adapts to any wallpaper.", "Glass"),
    ("omarchy-sunset-drive-theme", "https://github.com/bjarneo/omarchy-sunset-drive-theme", "Sunset-inspired theme with warm gradients.", "Sunset"),
    ("omarchy-synthwave84-theme", "https://github.com/bjarneo/omarchy-synthwave84-theme", "Synthwave 84 inspired theme with retro neon aesthetics.", "Synth"),
    ("omarchy-thegreek-theme", "https://github.com/bjarneo/omarchy-thegreek-theme", "Sleek, strategic spy theme with espionage intrigue.", "Spy"),
    ("omarchy-tycho", "https://github.com/bjarneo/omarchy-tycho", "Minimalist pastel theme inspired by musician Tycho.", "Ambient"),
    ("omarchy-velvetnight-theme", "https://github.com/bjarneo/omarchy-velvetnight-theme", "Dark, night-inspired theme with soft contrasts.", "Velvet"),
    ("omarchy-venice-from-above", "https://github.com/bjarneo/omarchy-venice-from-above", "A light theme inspired by bird's eye view of Venice.", "Venice"),
    ("omarchy-vesper-theme", "https://github.com/bjarneo/omarchy-vesper-theme", "Dark theme with warm vesper-orange highlights.", "Vesper"),
    ("omarchy-vhs80-theme", "https://github.com/bjarneo/omarchy-vhs80-theme", "Retro VHS-inspired theme with 80s aesthetics.", "VHS"),
    ("omarchy-void-theme", "https://github.com/bjarneo/omarchy-void-theme", "Low-contrast purple theme with soft accents.", "Void"),
    ("omarchy-wasteland-theme", "https://github.com/bjarneo/omarchy-wasteland-theme", "Post-apocalyptic wasteland-inspired color scheme.", "Wasteland"),
    ("omarchy-waveform-dark-theme", "https://github.com/bjarneo/omarchy-waveform-dark-theme", "Dark theme with waveform-inspired patterns.", "Audio"),
    ("omarchy-whitegold-theme", "https://github.com/bjarneo/omarchy-whitegold-theme", "Light and elegance intertwined with gold accents.", "Gold"),
    ("pink-blood-omarchy-theme", "https://github.com/bjarneo/pink-blood-omarchy-theme", "Bold pink-themed design with sharp dark canvas.", "Pink")
]

CURATED_CURSOR_SOURCES = [
    {
        "id": "Bibata-Modern-Classic",
        "name": "Bibata Modern Classic",
        "type": "cursor",
        "author": "ful1e5",
        "style": "dark",
        "url": "https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Classic.tar.xz",
        "description": "Clean, rounded black cursor with sharp white outline."
    },
    {
        "id": "Bibata-Modern-Amber",
        "name": "Bibata Modern Amber",
        "type": "cursor",
        "author": "ful1e5",
        "style": "amber",
        "url": "https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Amber.tar.xz",
        "description": "Warm golden amber cursor with high contrast."
    },
    {
        "id": "Bibata-Modern-Ice",
        "name": "Bibata Modern Ice",
        "type": "cursor",
        "author": "ful1e5",
        "style": "light",
        "url": "https://github.com/ful1e5/Bibata_Cursor/releases/download/v2.0.7/Bibata-Modern-Ice.tar.xz",
        "description": "Crisp snow-white modern cursor with dark borders."
    },
    {
        "id": "catppuccin-mocha-dark-cursors",
        "name": "Catppuccin Mocha Dark Cursors",
        "type": "cursor",
        "author": "catppuccin",
        "style": "dark",
        "url": "https://github.com/catppuccin/cursors/releases/download/v2.0.0/catppuccin-mocha-dark-cursors.zip",
        "description": "Soothing pastel dark cursor pack for Catppuccin lovers."
    },
    {
        "id": "catppuccin-latte-light-cursors",
        "name": "Catppuccin Latte Light Cursors",
        "type": "cursor",
        "author": "catppuccin",
        "style": "light",
        "url": "https://github.com/catppuccin/cursors/releases/download/v2.0.0/catppuccin-latte-light-cursors.zip",
        "description": "Clean pastel light cursor pack for light theme users."
    },
    {
        "id": "Nordzy-cursors",
        "name": "Nordzy Cursors",
        "type": "cursor",
        "author": "alvatip",
        "style": "dark",
        "url": "https://github.com/guillaumeboehm/Nordzy-cursors/releases/download/v2.4.0/Nordzy-cursors.tar.gz",
        "description": "Nordic arctic-blue themed vector cursor set."
    }
]


def load_unique_cdn_wallpapers():
    cache_f = Path("/tmp/bjarneo_unique_wallpapers.json")
    if cache_f.exists():
        try:
            with open(cache_f, "r") as f:
                arr = json.load(f)
                if arr and len(arr) > 100:
                    return arr
        except Exception:
            pass
    return [
        "https://wallpapers.hel1.your-objectstorage.com/dark/blue/10667x6000_omarchy_glass-sphere__01-glass-sphere.jpg"
    ]


def get_cached_thumbnail_path(remote_url):
    """Downloads remote wallpaper to local cache on demand and returns local file:// path."""
    if not remote_url or not remote_url.startswith("http"):
        return remote_url

    THUMBNAIL_DIR.mkdir(parents=True, exist_ok=True)
    h = hashlib.sha256(remote_url.encode("utf-8")).hexdigest()[:16]
    ext = remote_url.split(".")[-1].split("?")[0]
    if ext not in ("jpg", "jpeg", "png", "webp"):
        ext = "jpg"
    cached_file = THUMBNAIL_DIR / f"thumb_{h}.{ext}"

    if cached_file.exists() and cached_file.stat().st_size > 500:
        return f"file://{str(cached_file)}"

    return remote_url


def prefetch_thumbnails(urls, limit=30):
    """Prefetches and caches thumbnails for snappy local display."""
    THUMBNAIL_DIR.mkdir(parents=True, exist_ok=True)
    count = 0
    for u in urls:
        if count >= limit or not u or not u.startswith("http"):
            continue
        h = hashlib.sha256(u.encode("utf-8")).hexdigest()[:16]
        ext = u.split(".")[-1].split("?")[0]
        if ext not in ("jpg", "jpeg", "png", "webp"):
            ext = "jpg"
        target = THUMBNAIL_DIR / f"thumb_{h}.{ext}"
        if not target.exists() or target.stat().st_size < 500:
            try:
                req = urllib.request.Request(u, headers={"User-Agent": "Mozilla/5.0"})
                with urllib.request.urlopen(req, timeout=3.0) as resp, open(target, "wb") as out_f:
                    shutil.copyfileobj(resp, out_f)
                count += 1
            except Exception:
                pass


def write_atomic(path, data):
    p = Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    raw_bytes = (json.dumps(data, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    if len(raw_bytes) > MAX_STATE_BYTES:
        print(f"Error: Payload size {len(raw_bytes)} exceeds {MAX_STATE_BYTES}", file=sys.stderr)
        return

    handle, temp_name = tempfile.mkstemp(dir=str(p.parent), suffix=".tmp")
    try:
        os.fchmod(handle, 0o600)
        with os.fdopen(handle, "wb") as stream:
            stream.write(raw_bytes)
            stream.flush()
            os.fsync(stream.fileno())
        if p.exists():
            st = p.lstat()
            if not stat.S_ISREG(st.st_mode) or st.st_uid != os.getuid():
                p.unlink(missing_ok=True)
        os.replace(temp_name, p)
    except BaseException:
        Path(temp_name).unlink(missing_ok=True)
        raise


def load_config():
    if not CONFIG_FILE.exists():
        default_cfg = {
            "selectedThemes": None,
            "selectedCursors": None,
            "customSources": [],
            "customCursorSources": [],
            "cursorSize": 24,
            "randomizeWallpaper": True,
            "timerHours": 0,  # 0: Off, 1: 1h, 12: 12h, 24: 24h, or custom float/int
            "timerMode": "combo",  # combo, theme, cursor, wallpaper
            "lastRollTimestamp": 0
        }
        write_atomic(CONFIG_FILE, default_cfg)
        return default_cfg
    try:
        with open(CONFIG_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def save_config(cfg):
    write_atomic(CONFIG_FILE, cfg)


def parse_colors_toml(path):
    colors = {
        "accent": "#7aa2f7",
        "background": "#1a1b26",
        "foreground": "#a9b1d6",
        "red": "#f7768e",
        "green": "#9ece6a",
        "yellow": "#e0af68",
        "blue": "#7aa2f7"
    }
    if not path.exists():
        return colors
    try:
        for line in path.read_text(encoding="utf-8", errors="ignore").splitlines():
            line = line.strip()
            if "=" in line and not line.startswith("#"):
                k, v = line.split("=", 1)
                k = k.strip()
                v = v.strip().strip('"').strip("'")
                if k in colors:
                    colors[k] = v
    except Exception:
        pass
    return colors


def get_current_theme():
    try:
        res = subprocess.run(["omarchy", "theme", "current"], capture_output=True, text=True, timeout=2.0)
        if res.returncode == 0 and res.stdout.strip():
            return res.stdout.strip()
    except Exception:
        pass
    return "Unknown"


def get_current_cursor():
    cursor_name = "default"
    cursor_size = 24
    try:
        res = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", "cursor-theme"], capture_output=True, text=True, timeout=1.0)
        if res.returncode == 0 and res.stdout.strip():
            cursor_name = res.stdout.strip().strip("'").strip('"')
    except Exception:
        pass
    try:
        res2 = subprocess.run(["gsettings", "get", "org.gnome.desktop.interface", "cursor-size"], capture_output=True, text=True, timeout=1.0)
        if res2.returncode == 0 and res2.stdout.strip():
            cursor_size = int(res2.stdout.strip())
    except Exception:
        pass
    return cursor_name, cursor_size


def get_current_wallpaper():
    try:
        res = subprocess.run(["omarchy", "theme", "bg", "current"], capture_output=True, text=True, timeout=2.0)
        if res.returncode == 0 and res.stdout.strip():
            return res.stdout.strip()
    except Exception:
        pass
    return "Default"


def scan_themes():
    themes = []
    seen = set()

    search_dirs = [
        Path.home() / ".config" / "omarchy" / "themes",
        Path("/usr/share/omarchy/themes")
    ]

    for sdir in search_dirs:
        if not sdir.exists():
            continue
        for entry in sorted(sdir.iterdir()):
            if entry.is_dir() and not entry.name.startswith("."):
                t_id = entry.name
                if t_id in seen:
                    continue
                seen.add(t_id)

                colors_file = entry / "colors.toml"
                colors = parse_colors_toml(colors_file)
                display_name = " ".join(w.capitalize() for w in t_id.replace("-", " ").replace("_", " ").split())
                
                bg_dir = entry / "backgrounds"
                wallpapers = []
                primary_thumbnail = ""
                if bg_dir.exists():
                    for bg_f in sorted(bg_dir.iterdir()):
                        if bg_f.is_file() and bg_f.suffix.lower() in (".jpg", ".jpeg", ".png", ".webp"):
                            wallpapers.append({
                                "name": bg_f.stem.replace("-", " ").capitalize(),
                                "path": str(bg_f)
                            })
                    if wallpapers:
                        primary_thumbnail = wallpapers[0]["path"]

                preview_path = str(entry / "preview.png") if (entry / "preview.png").exists() else ""
                if not primary_thumbnail and preview_path:
                    primary_thumbnail = preview_path

                themes.append({
                    "id": t_id,
                    "name": display_name,
                    "isUser": (sdir == search_dirs[0]),
                    "path": str(entry),
                    "previewPath": preview_path,
                    "thumbnail": primary_thumbnail,
                    "wallpaperCount": len(wallpapers),
                    "wallpapers": wallpapers,
                    "colors": colors
                })

    return themes


def scan_cursors():
    cursors = []
    seen = set()

    search_dirs = [
        Path.home() / ".icons",
        Path.home() / ".local" / "share" / "icons",
        Path("/usr/share/icons")
    ]

    for sdir in search_dirs:
        if not sdir.exists():
            continue
        for entry in sorted(sdir.iterdir()):
            if entry.is_dir() and not entry.name.startswith("."):
                cursors_dir = entry / "cursors"
                index_theme = entry / "index.theme"
                if cursors_dir.exists() or index_theme.exists():
                    c_id = entry.name
                    if c_id in seen or c_id in ("default", "hicolor"):
                        continue
                    seen.add(c_id)

                    display_name = " ".join(w.capitalize() for w in c_id.replace("-", " ").replace("_", " ").split())
                    
                    cursors.append({
                        "id": c_id,
                        "name": display_name,
                        "isUser": (sdir != search_dirs[2]),
                        "path": str(entry)
                    })

    return cursors


def build_full_community_catalog():
    catalog = []
    unique_cdn = load_unique_cdn_wallpapers()
    
    for idx, (raw_id, url, desc, cat) in enumerate(RAW_COMMUNITY_THEMES):
        clean_name = " ".join(w.capitalize() for w in raw_id.replace("omarchy-", "").replace("-theme", "").replace(".theme", "").replace("-", " ").replace("/", " ").split())
        slug = url.replace("https://github.com/", "").strip("/")
        author = slug.split("/")[0] if "/" in slug else "community"
        
        if slug in REPO_BACKGROUND_MAP:
            wp_url = REPO_BACKGROUND_MAP[slug]
        else:
            wp_url = unique_cdn[(idx * 17) % len(unique_cdn)]
        
        local_thumb = get_cached_thumbnail_path(wp_url)
        
        catalog.append({
            "id": raw_id.lower().replace("/", "-").replace(".", "-"),
            "name": clean_name,
            "author": author,
            "url": url,
            "category": cat,
            "wallpaperUrl": local_thumb,
            "remoteUrl": wp_url,
            "description": desc,
            "isCustomSource": False,
            "colors": PALETTE_PRESETS[idx % len(PALETTE_PRESETS)]
        })

    cfg = load_config()
    for idx, src in enumerate(cfg.get("customSources", [])):
        c_url = src.get("url", "").strip()
        if not c_url:
            continue
        c_name = src.get("name", "Custom Theme Source")
        c_id = "custom-" + hashlib.md5(c_url.encode()).hexdigest()[:8]
        slug = c_url.replace("https://github.com/", "").strip("/")
        author = slug.split("/")[0] if "/" in slug else "custom"
        wp_url = src.get("wallpaperUrl") or unique_cdn[(idx * 31 + 7) % len(unique_cdn)]
        local_thumb = get_cached_thumbnail_path(wp_url)

        catalog.insert(0, {
            "id": c_id,
            "name": c_name,
            "author": author,
            "url": c_url,
            "category": "Custom Source",
            "wallpaperUrl": local_thumb,
            "remoteUrl": wp_url,
            "description": src.get("description", f"Custom repository source: {c_url}"),
            "isCustomSource": True,
            "colors": PALETTE_PRESETS[(idx + 3) % len(PALETTE_PRESETS)]
        })

    return catalog


def build_full_cursor_catalog():
    catalog = []
    for item in CURATED_CURSOR_SOURCES:
        c_item = dict(item)
        c_item["isCustomSource"] = False
        catalog.append(c_item)

    cfg = load_config()
    for idx, src in enumerate(cfg.get("customCursorSources", [])):
        c_url = src.get("url", "").strip()
        if not c_url:
            continue
        c_name = src.get("name", "Custom Cursor Pack")
        c_id = src.get("id") or ("custom-cur-" + hashlib.md5(c_url.encode()).hexdigest()[:8])
        slug = c_url.replace("https://github.com/", "").strip("/")
        author = slug.split("/")[0] if "/" in slug else "custom"

        catalog.insert(0, {
            "id": c_id,
            "name": c_name,
            "author": author,
            "url": c_url,
            "style": "custom",
            "type": "cursor",
            "description": src.get("description", f"Custom cursor archive: {c_url}"),
            "isCustomSource": True
        })
    return catalog


def fetch_online_themes_cached():
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    if ONLINE_THEMES_CACHE.exists():
        try:
            mtime = ONLINE_THEMES_CACHE.stat().st_mtime
            if (time.time() - mtime) < CACHE_TTL:
                with open(ONLINE_THEMES_CACHE, "r", encoding="utf-8") as f:
                    cached = json.load(f)
                    if isinstance(cached, list) and len(cached) > 0:
                        return cached
        except Exception:
            pass

    full_catalog = build_full_community_catalog()
    try:
        write_atomic(ONLINE_THEMES_CACHE, full_catalog)
    except Exception:
        pass
    return full_catalog


def add_custom_source(name, url, desc="", src_type="theme"):
    cfg = load_config()
    key = "customCursorSources" if src_type == "cursor" else "customSources"
    sources = cfg.get(key, [])
    url = url.strip()
    if not url:
        return False, "URL cannot be empty"
    
    for s in sources:
        if s.get("url") == url:
            s["name"] = name
            s["description"] = desc
            save_config(cfg)
            Path(ONLINE_THEMES_CACHE).unlink(missing_ok=True)
            return True, f"Updated existing {src_type} source."

    sources.append({
        "id": ("src-cur-" if src_type == "cursor" else "src-") + hashlib.md5(url.encode()).hexdigest()[:8],
        "name": name or (f"Custom {src_type.capitalize()} Pack"),
        "url": url,
        "description": desc or f"Custom {src_type} source: {url}"
    })
    cfg[key] = sources
    save_config(cfg)
    Path(ONLINE_THEMES_CACHE).unlink(missing_ok=True)
    return True, f"Custom {src_type} source added successfully."


def delete_custom_source(src_id_or_url, src_type="theme"):
    cfg = load_config()
    key = "customCursorSources" if src_type == "cursor" else "customSources"
    sources = cfg.get(key, [])
    filtered = [s for s in sources if s.get("id") != src_id_or_url and s.get("url") != src_id_or_url]
    if len(filtered) != len(sources):
        cfg[key] = filtered
        save_config(cfg)
        Path(ONLINE_THEMES_CACHE).unlink(missing_ok=True)
        return True, f"{src_type.capitalize()} source deleted."
    return False, f"{src_type.capitalize()} source not found."


def edit_custom_source(src_id, new_name, new_url, src_type="theme"):
    cfg = load_config()
    key = "customCursorSources" if src_type == "cursor" else "customSources"
    sources = cfg.get(key, [])
    found = False
    for s in sources:
        if s.get("id") == src_id:
            s["name"] = new_name
            s["url"] = new_url
            found = True
            break
    if found:
        cfg[key] = sources
        save_config(cfg)
        Path(ONLINE_THEMES_CACHE).unlink(missing_ok=True)
        return True, f"{src_type.capitalize()} source edited successfully."
    return False, f"{src_type.capitalize()} source not found."


def set_randomizer_timer(hours, mode="combo"):
    """Configures background randomizer timer in hours (0 for Off)."""
    cfg = load_config()
    try:
        val = float(hours)
    except Exception:
        val = 0.0
    cfg["timerHours"] = val
    if mode:
        cfg["timerMode"] = mode
    cfg["lastRollTimestamp"] = int(time.time())
    save_config(cfg)
    return True, f"Randomizer timer set to {val} hour(s)."


def check_and_run_timer():
    """Called periodically by Widget timer to perform background roll if interval elapsed."""
    cfg = load_config()
    timer_hours = float(cfg.get("timerHours", 0.0))
    if timer_hours <= 0.0:
        return False, "Timer is disabled"

    interval_sec = timer_hours * 3600.0
    last_roll = float(cfg.get("lastRollTimestamp", 0.0))
    now = time.time()

    if (now - last_roll) >= interval_sec:
        mode = cfg.get("timerMode", "combo")
        randomize(mode)
        cfg["lastRollTimestamp"] = int(now)
        save_config(cfg)
        return True, f"Timer triggered: Rolled {mode}"
    return False, f"Timer pending: {int((interval_sec - (now - last_roll)) / 60)} minutes remaining"


def apply_theme(theme_name):
    try:
        cmd = ["omarchy", "theme", "set", theme_name]
        res = subprocess.run(cmd, capture_output=True, text=True, timeout=10.0)
        return res.returncode == 0, res.stdout + res.stderr
    except Exception as e:
        return False, str(e)


def apply_cursor(cursor_name, size=24):
    success = True
    output = []
    try:
        res1 = subprocess.run(["hyprctl", "setcursor", cursor_name, str(size)], capture_output=True, text=True, timeout=2.0)
        output.append(f"hyprctl: {res1.stdout.strip()}")
    except Exception as e:
        output.append(f"hyprctl error: {e}")

    try:
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "cursor-theme", cursor_name], timeout=2.0)
        subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "cursor-size", str(size)], timeout=2.0)
    except Exception:
        pass

    cfg = load_config()
    cfg["cursorSize"] = int(size)
    save_config(cfg)

    return success, "\n".join(output)


def set_wallpaper_path(path):
    try:
        res = subprocess.run(["omarchy", "theme", "bg", "set", str(path)], capture_output=True, text=True, timeout=3.0)
        return res.returncode == 0
    except Exception:
        return False


def next_wallpaper():
    try:
        res = subprocess.run(["omarchy", "theme", "bg", "next"], capture_output=True, text=True, timeout=3.0)
        return res.returncode == 0
    except Exception:
        return False


def remove_item(item_type, item_id):
    try:
        if item_type == "theme":
            target = Path.home() / ".config" / "omarchy" / "themes" / item_id
            if target.exists():
                shutil.rmtree(target)
                return True, f"Theme {item_id} removed."
            res = subprocess.run(["omarchy", "theme", "remove", item_id], capture_output=True, text=True, timeout=5.0)
            return res.returncode == 0, res.stdout + res.stderr
        elif item_type == "cursor":
            for base in [Path.home() / ".local" / "share" / "icons" / item_id, Path.home() / ".icons" / item_id]:
                if base.exists():
                    shutil.rmtree(base)
                    return True, f"Cursor pack {item_id} removed."
            return False, "Cursor pack not found in user directory."
    except Exception as e:
        return False, str(e)


def install_theme_repo(url):
    try:
        url = url.strip()
        if not url.startswith("http://") and not url.startswith("https://") and not url.startswith("git@"):
            return False, "Invalid repository URL format"

        repo_name = url.rstrip("/").split("/")[-1]
        if repo_name.endswith(".git"):
            repo_name = repo_name[:-4]

        target_dir = Path.home() / ".config" / "omarchy" / "themes" / repo_name
        if target_dir.exists():
            return False, f"Theme directory {repo_name} already exists."

        target_dir.parent.mkdir(parents=True, exist_ok=True)
        res = subprocess.run(["git", "clone", "--depth", "1", url, str(target_dir)], capture_output=True, text=True, timeout=30.0)
        if res.returncode == 0:
            return True, f"Theme {repo_name} installed successfully."
        return False, res.stderr
    except Exception as e:
        return False, str(e)


def install_cursor_archive(url):
    try:
        url = url.strip()
        dest_base = Path.home() / ".local" / "share" / "icons"
        dest_base.mkdir(parents=True, exist_ok=True)

        with tempfile.TemporaryDirectory() as tmp_dir:
            tmp_path = Path(tmp_dir)
            archive_path = tmp_path / "downloaded_cursor"

            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0 (X11; Linux x86_64)"})
            with urllib.request.urlopen(req, timeout=45.0) as resp, open(archive_path, "wb") as out_file:
                shutil.copyfileobj(resp, out_file)

            extract_dir = tmp_path / "extracted"
            extract_dir.mkdir()

            if tarfile.is_tarfile(archive_path):
                with tarfile.open(archive_path, "r:*") as tar:
                    tar.extractall(path=extract_dir)
            elif zipfile.is_zipfile(archive_path):
                with zipfile.ZipFile(archive_path, "r") as zf:
                    zf.extractall(path=extract_dir)
            else:
                return False, "Downloaded file is not a supported tar or zip archive."

            installed = []
            for root, dirs, files in os.walk(extract_dir):
                if "cursors" in dirs or "index.theme" in files:
                    src_theme_dir = Path(root)
                    theme_name = src_theme_dir.name
                    if theme_name != "extracted":
                        target = dest_base / theme_name
                        if target.exists():
                            shutil.rmtree(target)
                        shutil.copytree(src_theme_dir, target)
                        installed.append(theme_name)

            if installed:
                return True, f"Installed cursors: {', '.join(installed)}"
            return False, "No valid cursor theme structure found in archive."
    except Exception as e:
        return False, str(e)


def poll_status():
    config = load_config()
    themes = scan_themes()
    cursors = scan_cursors()
    curr_theme = get_current_theme()
    curr_cursor, curr_cursor_size = get_current_cursor()
    curr_wallpaper = get_current_wallpaper()

    all_theme_ids = [t["id"] for t in themes]
    all_cursor_ids = [c["id"] for c in cursors]

    if config.get("selectedThemes") is None:
        selected_themes = all_theme_ids
        config["selectedThemes"] = selected_themes
        save_config(config)
    else:
        selected_themes = config.get("selectedThemes", [])

    if config.get("selectedCursors") is None:
        selected_cursors = all_cursor_ids
        config["selectedCursors"] = selected_cursors
        save_config(config)
    else:
        selected_cursors = config.get("selectedCursors", [])

    installed_cursor_ids = {c["id"].lower() for c in cursors}
    installed_theme_ids = {t["id"].lower() for t in themes}

    online_themes = fetch_online_themes_cached()
    theme_sources_with_status = []
    for s in online_themes:
        item = dict(s)
        s_id_clean = s["id"].lower().replace("_", "-")
        item["installed"] = any(s_id_clean in t_id or s["name"].lower() in t_id for t_id in installed_theme_ids)
        theme_sources_with_status.append(item)

    full_cursor_catalog = build_full_cursor_catalog()
    cursor_sources_with_status = []
    for s in full_cursor_catalog:
        item = dict(s)
        s_id_clean = s["id"].lower().replace("_", "-")
        item["installed"] = any(s_id_clean in c_id or c_id in s_id_clean for c_id in installed_cursor_ids)
        cursor_sources_with_status.append(item)

    user_installed = []
    for t in themes:
        if t["isUser"]:
            user_installed.append({ "type": "theme", "id": t["id"], "name": t["name"], "path": t["path"] })
    for c in cursors:
        if c["isUser"]:
            user_installed.append({ "type": "cursor", "id": c["id"], "name": c["name"], "path": c["path"] })

    doc = {
        "version": 1,
        "updatedAt": int(time.time()),
        "currentTheme": curr_theme,
        "currentCursor": curr_cursor,
        "currentCursorSize": curr_cursor_size,
        "currentWallpaper": curr_wallpaper,
        "randomizeWallpaper": config.get("randomizeWallpaper", True),
        "timerHours": config.get("timerHours", 0),
        "timerMode": config.get("timerMode", "combo"),
        "lastRollTimestamp": config.get("lastRollTimestamp", 0),
        "selectedThemes": selected_themes,
        "selectedCursors": selected_cursors,
        "customSources": config.get("customSources", []),
        "customCursorSources": config.get("customCursorSources", []),
        "themes": themes,
        "cursors": cursors,
        "userInstalled": user_installed,
        "themeSources": theme_sources_with_status,
        "cursorSources": cursor_sources_with_status
    }

    write_atomic(STATE_FILE, doc)
    return doc


def randomize(mode="combo"):
    config = load_config()
    themes = scan_themes()
    cursors = scan_cursors()

    allowed_theme_ids = set(config.get("selectedThemes", [t["id"] for t in themes]))
    allowed_cursor_ids = set(config.get("selectedCursors", [c["id"] for c in cursors]))
    rand_wallpaper = config.get("randomizeWallpaper", True)

    eligible_themes = [t for t in themes if t["id"] in allowed_theme_ids]
    if not eligible_themes:
        eligible_themes = themes

    eligible_cursors = [c for c in cursors if c["id"] in allowed_cursor_ids]
    if not eligible_cursors:
        eligible_cursors = cursors

    chosen_theme = random.choice(eligible_themes) if eligible_themes else None
    chosen_cursor = random.choice(eligible_cursors) if eligible_cursors else None

    result = {}
    if (mode in ("combo", "theme")) and chosen_theme:
        ok, msg = apply_theme(chosen_theme["name"])
        result["theme"] = {"id": chosen_theme["id"], "name": chosen_theme["name"], "success": ok}
        if rand_wallpaper and chosen_theme.get("wallpapers"):
            chosen_bg = random.choice(chosen_theme["wallpapers"])
            set_wallpaper_path(chosen_bg["path"])
            result["wallpaper"] = chosen_bg["name"]

    if (mode in ("combo", "cursor")) and chosen_cursor:
        ok, msg = apply_cursor(chosen_cursor["id"], config.get("cursorSize", 24))
        result["cursor"] = {"id": chosen_cursor["id"], "name": chosen_cursor["name"], "success": ok}

    if mode == "wallpaper":
        next_wallpaper()
        result["wallpaper"] = "cycled"

    poll_status()
    print(json.dumps({"ok": True, "result": result}))


def main():
    parser = argparse.ArgumentParser(description="OmaChroma Engine")
    parser.add_argument("--poll", action="store_true", help="Scan and write status.json")
    parser.add_argument("--set-theme", type=str, help="Apply theme by name")
    parser.add_argument("--set-cursor", type=str, help="Apply cursor theme by id")
    parser.add_argument("--cursor-size", type=int, default=24, help="Cursor size")
    parser.add_argument("--set-wallpaper", type=str, help="Set wallpaper by path")
    parser.add_argument("--next-wallpaper", action="store_true", help="Cycle next wallpaper")
    parser.add_argument("--randomize", choices=["combo", "theme", "cursor", "wallpaper"], help="Randomize styling")
    parser.add_argument("--install-theme", type=str, help="Install theme git URL")
    parser.add_argument("--install-cursor", type=str, help="Download & install cursor archive URL")
    parser.add_argument("--remove-item", nargs=2, metavar=("TYPE", "ID"), help="Remove user theme or cursor")
    parser.add_argument("--restart-shell", action="store_true", help="Restart Omarchy shell")
    parser.add_argument("--toggle-theme-selection", type=str, help="Toggle theme in randomize checklist")
    parser.add_argument("--toggle-cursor-selection", type=str, help="Toggle cursor in randomize checklist")
    parser.add_argument("--set-timer", type=str, help="Set timer interval in hours (0, 1, 12, 24, or custom float)")
    parser.add_argument("--check-timer", action="store_true", help="Check and execute background timer roll")
    parser.add_argument("--add-source", nargs=2, metavar=("NAME", "URL"), help="Add custom theme source")
    parser.add_argument("--delete-source", type=str, help="Delete custom theme source by ID or URL")
    parser.add_argument("--edit-source", nargs=3, metavar=("ID", "NAME", "URL"), help="Edit custom theme source")
    parser.add_argument("--add-cursor-source", nargs=2, metavar=("NAME", "URL"), help="Add custom cursor source")
    parser.add_argument("--delete-cursor-source", type=str, help="Delete custom cursor source by ID or URL")
    parser.add_argument("--edit-cursor-source", nargs=3, metavar=("ID", "NAME", "URL"), help="Edit custom cursor source")
    parser.add_argument("--prefetch-cache", action="store_true", help="Prefetch first 20 store thumbnails to local disk cache")
    parser.add_argument("--save-config", action="store_true", help="Save config JSON from stdin")
    args = parser.parse_args()

    if args.set_timer is not None:
        ok, msg = set_randomizer_timer(args.set_timer)
        poll_status()
        print(json.dumps({"ok": ok, "message": msg}))
    elif args.check_timer:
        ok, msg = check_and_run_timer()
        print(json.dumps({"ok": ok, "message": msg}))
    elif args.add_source:
        ok, msg = add_custom_source(args.add_source[0], args.add_source[1], src_type="theme")
        poll_status()
        print(json.dumps({"ok": ok, "message": msg}))
    elif args.delete_source:
        ok, msg = delete_custom_source(args.delete_source, src_type="theme")
        poll_status()
        print(json.dumps({"ok": ok, "message": msg}))
    elif args.edit_source:
        ok, msg = edit_custom_source(args.edit_source[0], args.edit_source[1], args.edit_source[2], src_type="theme")
        poll_status()
        print(json.dumps({"ok": ok, "message": msg}))
    elif args.add_cursor_source:
        ok, msg = add_custom_source(args.add_cursor_source[0], args.add_cursor_source[1], src_type="cursor")
        poll_status()
        print(json.dumps({"ok": ok, "message": msg}))
    elif args.delete_cursor_source:
        ok, msg = delete_custom_source(args.delete_cursor_source, src_type="cursor")
        poll_status()
        print(json.dumps({"ok": ok, "message": msg}))
    elif args.edit_cursor_source:
        ok, msg = edit_custom_source(args.edit_cursor_source[0], args.edit_cursor_source[1], args.edit_cursor_source[2], src_type="cursor")
        poll_status()
        print(json.dumps({"ok": ok, "message": msg}))
    elif args.prefetch_cache:
        urls = list(REPO_BACKGROUND_MAP.values())
        prefetch_thumbnails(urls, limit=30)
        poll_status()
        print(json.dumps({"ok": True, "cached": len(urls)}))
    elif args.toggle_theme_selection:
        t_id = args.toggle_theme_selection
        cfg = load_config()
        themes = scan_themes()
        sel = list(cfg.get("selectedThemes") or [t["id"] for t in themes])
        if t_id in sel:
            sel.remove(t_id)
        else:
            sel.append(t_id)
        cfg["selectedThemes"] = sel
        save_config(cfg)
        poll_status()
        print(json.dumps({"ok": True, "selectedThemes": sel}))
    elif args.toggle_cursor_selection:
        c_id = args.toggle_cursor_selection
        cfg = load_config()
        cursors = scan_cursors()
        sel = list(cfg.get("selectedCursors") or [c["id"] for c in cursors])
        if c_id in sel:
            sel.remove(c_id)
        else:
            sel.append(c_id)
        cfg["selectedCursors"] = sel
        save_config(cfg)
        poll_status()
        print(json.dumps({"ok": True, "selectedCursors": sel}))
    elif args.save_config:
        try:
            payload = json.loads(sys.stdin.read())
            cfg = load_config()
            cfg.update(payload)
            save_config(cfg)
            poll_status()
            print(json.dumps({"ok": True}))
        except Exception as e:
            print(json.dumps({"ok": False, "error": str(e)}))
    elif args.restart_shell:
        subprocess.run(["omarchy", "restart", "shell"])
        print(json.dumps({"ok": True}))
    elif args.set_theme:
        ok, msg = apply_theme(args.set_theme)
        poll_status()
        print(json.dumps({"ok": ok, "message": msg}))
    elif args.set_cursor:
        ok, msg = apply_cursor(args.set_cursor, args.cursor_size)
        poll_status()
        print(json.dumps({"ok": ok, "message": msg}))
    elif args.set_wallpaper:
        ok = set_wallpaper_path(args.set_wallpaper)
        poll_status()
        print(json.dumps({"ok": ok}))
    elif args.next_wallpaper:
        ok = next_wallpaper()
        poll_status()
        print(json.dumps({"ok": ok}))
    elif args.randomize:
        randomize(args.randomize)
    elif args.remove_item:
        ok, msg = remove_item(args.remove_item[0], args.remove_item[1])
        poll_status()
        print(json.dumps({"ok": ok, "message": msg}))
    elif args.install_theme:
        ok, msg = install_theme_repo(args.install_theme)
        poll_status()
        print(json.dumps({"ok": ok, "message": msg}))
    elif args.install_cursor:
        ok, msg = install_cursor_archive(args.install_cursor)
        poll_status()
        print(json.dumps({"ok": ok, "message": msg}))
    else:
        doc = poll_status()
        print(f"OmaChroma: {len(doc['themes'])} installed themes, {len(doc['themeSources'])} store themes, {len(doc['cursors'])} cursors. Active: {doc['currentTheme']} / {doc['currentCursor']}")


if __name__ == "__main__":
    main()
