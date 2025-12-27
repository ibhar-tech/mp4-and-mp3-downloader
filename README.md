# 📺 YouTube Downloader for Termux

A powerful, easy-to-use YouTube downloader for Android using Termux. Share any YouTube video or playlist directly to Termux to download high-quality videos or MP3 audio.

![Platform](https://img.shields.io/badge/Platform-Android%20(Termux)-green)
![Tool](https://img.shields.io/badge/Tool-yt--dlp-red)
![License](https://img.shields.io/badge/License-MIT-blue)

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🎬 **Video Download** | High quality MP4 with original audio (not dubbed) |
| 🎵 **Audio Download** | MP3 format with original language audio |
| 📋 **Playlist Support** | Download entire playlists with one click |
| 🌍 **Original Audio** | Automatically selects original language, not AI-dubbed |
| ⚡ **Smart Skipping** | Automatically skips private/deleted/unavailable videos |
| 🔄 **Auto-Retry** | Retries failed downloads up to 10 times |
| 📁 **Organized** | Playlists saved in their own folders |

## 📱 Screenshots

```
┌─────────────────────────────────────────┐
│  📋 PLAYLIST DETECTED                    │
│    Title: My Favorite Songs              │
│    Videos: 25                            │
│                                          │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│        DOWNLOAD OPTIONS                  │
│  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                          │
│  1) 🎬 Video (High Quality MP4)          │
│  2) 🎵 Audio Only (MP3)                  │
│                                          │
│  Choose [1/2] (default: 1): _            │
└─────────────────────────────────────────┘
```

## 🚀 Installation

### Prerequisites
- Android phone with [Termux](https://f-droid.org/en/packages/com.termux/) installed (from F-Droid, NOT Play Store)
- Storage permission granted to Termux

### Quick Install

1. **Open Termux** and run:
```bash
curl -sL https://raw.githubusercontent.com/ibhar-tech/mp4-and-mp3-downloader/main/termux_v2.sh | bash
```

Or manually:

```bash
# Clone the repo
git clone https://github.com/ibhar-tech/mp4-and-mp3-downloader.git
cd mp4-and-mp3-downloader

# Run the setup script
bash termux_v2.sh
```

2. **Grant storage permission** when prompted

3. **Done!** Share any YouTube link to Termux to start downloading

## 📖 Usage

### Download a Single Video
1. Open YouTube app
2. Share any video → Select "Termux"
3. Choose: `1` for Video or `2` for Audio
4. Wait for download to complete

### Download a Playlist
1. Open a YouTube playlist
2. Share the playlist link → Select "Termux"
3. Choose: `1` for Video or `2` for Audio
4. All available videos will be downloaded

### File Locations
```
/storage/emulated/0/Youtube/
├── Single_Video.mp4
├── Another_Video.mp4
├── PlaylistName/
│   ├── 001 - First_Video.mp4
│   ├── 002 - Second_Video.mp4
│   └── 003 - Third_Video.mp4
└── .download.log
```

## 🛡️ Edge Cases Handled

| Issue | How It's Handled |
|-------|------------------|
| Private videos | Skipped automatically |
| Deleted videos | Skipped automatically |
| Hidden videos | Skipped automatically |
| Age-restricted | Skipped with warning |
| Geo-blocked | Skipped with warning |
| Network errors | Auto-retry (10 attempts) |
| Rate limiting | Auto-delay between downloads |

## 🔧 Configuration

Downloads are saved to: `/storage/emulated/0/Youtube/`

To change the download location, edit the `OUT_DIR` variable in `~/bin/termux-url-opener`:
```bash
nano ~/bin/termux-url-opener
# Change: OUT_DIR="$HOME/storage/shared/Youtube"
```

## 📋 Files

| File | Description |
|------|-------------|
| `termux.sh` | Basic version - single video support |
| `termux_v2.sh` | Full version - playlist + edge case handling |

## 🔄 Updating

To update yt-dlp (recommended periodically):
```bash
pip install -U yt-dlp
```

To reinstall the script:
```bash
bash termux_v2.sh
```

## ❓ Troubleshooting

### "Permission denied" when saving files
```bash
termux-setup-storage
```

### "yt-dlp: command not found"
```bash
pip install -U yt-dlp
```

### Videos not downloading
Make sure you're using the latest yt-dlp:
```bash
pip install -U yt-dlp
```

### Arabic/non-Latin titles showing as underscores
This was fixed in v2. Make sure you're running the latest `termux_v2.sh`.

## 🙏 Credits

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - The powerful download engine
- [Termux](https://termux.dev/) - Android terminal emulator
- [FFmpeg](https://ffmpeg.org/) - Audio/video processing

## 📄 License

MIT License - feel free to use, modify, and distribute.

---

**Made with ❤️ for easy YouTube downloads on Android**
