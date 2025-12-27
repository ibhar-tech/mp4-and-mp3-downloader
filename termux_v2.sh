#!/data/data/com.termux/files/usr/bin/bash

# YouTube Downloader Setup Script v2
# Using yt-dlp with PLAYLIST support
# Handles: hidden videos, private videos, errors, rate limiting, etc.

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Update packages
log_info "Updating system packages..."
pkg update -y && pkg upgrade -y

# Install required packages
log_info "Installing required packages..."

# Install python and pip first (required for yt-dlp)
if ! command -v python >/dev/null 2>&1; then
    log_info "Installing python..."
    pkg install python -y
    log_success "python installed"
else
    log_success "python already installed"
fi

# Install yt-dlp via pip (more up-to-date than pkg version)
if ! command -v yt-dlp >/dev/null 2>&1; then
    log_info "Installing yt-dlp..."
    pip install -U yt-dlp
    log_success "yt-dlp installed"
else
    log_info "Updating yt-dlp..."
    pip install -U yt-dlp
    log_success "yt-dlp updated"
fi

# Install ffmpeg
if ! command -v ffmpeg >/dev/null 2>&1; then
    log_info "Installing ffmpeg..."
    pkg install ffmpeg -y
    log_success "ffmpeg installed"
else
    log_success "ffmpeg already installed"
fi

# Setup storage
if [ ! -d "$HOME/storage/shared" ]; then
    log_info "Setting up storage access..."
    termux-setup-storage
    sleep 2
fi

# Create directories
YT_DIR="$HOME/storage/shared/Youtube"
BIN_DIR="$HOME/bin"
mkdir -p "$YT_DIR" "$BIN_DIR"
log_success "Directories created: $YT_DIR, $BIN_DIR"

# Create the URL opener script
log_info "Creating termux-url-opener script (v2 with playlist support)..."
cat > "$BIN_DIR/termux-url-opener" << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash

# ============================================
# YouTube Downloader v2 - With Playlist Support
# ============================================
# Features:
# - Single video and playlist downloads
# - Original audio selection (not dubbed)
# - Handles hidden/private/deleted videos
# - Rate limiting protection
# - Detailed progress and error reporting

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

highlight() {
    echo -e "${CYAN}$1${NC}"
}

URL="$1"
OUT_DIR="$HOME/storage/shared/Youtube"
LOG_FILE="$OUT_DIR/.download.log"
ERROR_LOG="$OUT_DIR/.errors.log"

# Validate URL
if [[ -z "$URL" ]]; then
    error "No URL provided"
    exit 1
fi

# Check if URL is a YouTube link
if [[ ! "$URL" =~ (youtube\.com|youtu\.be) ]]; then
    error "Not a YouTube URL: $URL"
    exit 1
fi

# Ensure directories exist
mkdir -p "$OUT_DIR"

# Log start
{
    echo "======================================"
    echo "Download started: $(date)"
    echo "URL: $URL"
} >> "$LOG_FILE"

# ============================================
# DETECT URL TYPE (Single Video vs Playlist)
# ============================================
highlight "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "Analyzing URL..."

IS_PLAYLIST=0
PLAYLIST_COUNT=0
VIDEO_TITLE=""

# Check if it's a playlist
if [[ "$URL" =~ list= ]]; then
    # Get playlist info
    PLAYLIST_INFO=$(yt-dlp --flat-playlist --dump-json "$URL" 2>/dev/null | head -1)
    
    if [[ -n "$PLAYLIST_INFO" ]]; then
        IS_PLAYLIST=1
        # Count videos in playlist (including unavailable ones)
        PLAYLIST_COUNT=$(yt-dlp --flat-playlist --print "%(id)s" "$URL" 2>/dev/null | wc -l)
        PLAYLIST_TITLE=$(echo "$PLAYLIST_INFO" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('playlist_title', d.get('title', 'Unknown Playlist')))" 2>/dev/null || echo "Unknown Playlist")
        
        echo -e "${MAGENTA}📋 PLAYLIST DETECTED${NC}"
        echo "  Title: $PLAYLIST_TITLE"
        echo "  Videos: $PLAYLIST_COUNT"
    fi
else
    # Single video
    VIDEO_TITLE=$(yt-dlp --get-title "$URL" 2>/dev/null || echo "Unknown")
    echo -e "${CYAN}🎬 SINGLE VIDEO${NC}"
    echo "  Title: $VIDEO_TITLE"
fi

highlight "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================
# CHECK DISK SPACE
# ============================================
AVAILABLE_SPACE=$(df -h "$OUT_DIR" 2>/dev/null | awk 'NR==2 {print $4}' || echo "Unknown")
log "Available disk space: $AVAILABLE_SPACE"

# ============================================
# ASK USER: DOWNLOAD MODE
# ============================================
highlight "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${MAGENTA}        DOWNLOAD OPTIONS${NC}"
highlight "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1) 🎬 Video (High Quality MP4 with Original Audio)"
echo "  2) 🎵 Audio Only (MP3 - Original Language)"
echo ""

if [[ $IS_PLAYLIST -eq 1 ]]; then
    echo -e "  ${YELLOW}Note: Downloading playlist with $PLAYLIST_COUNT videos${NC}"
    echo -e "  ${YELLOW}Hidden/private videos will be skipped automatically${NC}"
    echo ""
fi

echo -n "Choose [1/2] (default: 1): "
read -t 30 CHOICE || CHOICE="1"
echo ""

case "$CHOICE" in
    2|audio|Audio|AUDIO|mp3|MP3)
        DOWNLOAD_MODE="audio"
        log "Mode: ${MAGENTA}AUDIO ONLY (MP3 - Original)${NC}"
        ;;
    *)
        DOWNLOAD_MODE="video"
        log "Mode: ${CYAN}HIGH QUALITY VIDEO (Original Audio)${NC}"
        ;;
esac

highlight "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================
# COMMON YT-DLP OPTIONS
# ============================================
# These options handle various edge cases:
# --ignore-errors          : Skip unavailable videos (private, deleted, etc.)
# --no-abort-on-error      : Continue even if some videos fail
# --retries 10             : Retry failed downloads up to 10 times
# --fragment-retries 10    : Retry failed fragments
# --sleep-interval 1       : Wait 1-3 seconds between downloads (rate limiting)
# --max-sleep-interval 3   : Maximum wait time
# --socket-timeout 30      : Timeout for network operations

COMMON_OPTS=(
    --ignore-errors
    --no-abort-on-error
    --retries 10
    --fragment-retries 10
    --sleep-interval 1
    --max-sleep-interval 3
    --socket-timeout 30
    --add-metadata
    --embed-thumbnail
    --progress
    --newline
)

# Add playlist-specific options
if [[ $IS_PLAYLIST -eq 1 ]]; then
    COMMON_OPTS+=(
        --yes-playlist
        -o "$OUT_DIR/%(playlist_title)s/%(playlist_index)03d - %(title)s.%(ext)s"
    )
else
    COMMON_OPTS+=(
        --no-playlist
        -o "$OUT_DIR/%(title)s.%(ext)s"
    )
fi

# ============================================
# DOWNLOAD FUNCTION
# ============================================
download_content() {
    local format_opts=("$@")
    local start_time=$(date +%s)
    local temp_error_log=$(mktemp)
    
    log "Starting download..."
    if [[ $IS_PLAYLIST -eq 1 ]]; then
        echo -e "${YELLOW}Downloading playlist: $PLAYLIST_TITLE${NC}"
        echo -e "${YELLOW}Progress will be shown for each video${NC}"
    fi
    echo ""
    
    # Run yt-dlp and capture output
    yt-dlp "${COMMON_OPTS[@]}" "${format_opts[@]}" "$URL" 2>&1 | tee "$temp_error_log"
    
    local result=${PIPESTATUS[0]}
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Parse results
    local downloaded=0
    local skipped=0
    local errors=0
    
    if [[ -f "$temp_error_log" ]]; then
        # Count occurrences safely (grep returns 1 if no match, so we handle it)
        downloaded=$(grep -c "has already been recorded" "$temp_error_log" 2>/dev/null) || downloaded=0
        count=$(grep -c "\[download\] 100%" "$temp_error_log" 2>/dev/null) || count=0
        downloaded=$((downloaded + count))
        
        skipped=$(grep -c "is not available" "$temp_error_log" 2>/dev/null) || skipped=0
        count=$(grep -c "Private video" "$temp_error_log" 2>/dev/null) || count=0
        skipped=$((skipped + count))
        count=$(grep -c "Video unavailable" "$temp_error_log" 2>/dev/null) || count=0
        skipped=$((skipped + count))
        count=$(grep -c "Sign in to confirm" "$temp_error_log" 2>/dev/null) || count=0
        skipped=$((skipped + count))
        
        errors=$(grep -c "ERROR:" "$temp_error_log" 2>/dev/null) || errors=0
        
        # Save errors to error log
        grep "ERROR:" "$temp_error_log" >> "$ERROR_LOG" 2>/dev/null || true
    fi
    
    rm -f "$temp_error_log"
    
    # Generate report
    echo ""
    highlight "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ $result -eq 0 ]] || [[ $downloaded -gt 0 ]]; then
        success "DOWNLOAD COMPLETE"
    else
        error "DOWNLOAD FAILED"
    fi
    
    highlight "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    if [[ $IS_PLAYLIST -eq 1 ]]; then
        echo "  Playlist: $PLAYLIST_TITLE"
        echo "  Total videos: $PLAYLIST_COUNT"
    else
        echo "  Title: $VIDEO_TITLE"
    fi
    
    echo "  Mode: $DOWNLOAD_MODE"
    echo "  Duration: ${duration}s"
    echo "  Location: $OUT_DIR"
    
    if [[ $IS_PLAYLIST -eq 1 ]]; then
        echo ""
        echo -e "  ${GREEN}✓ Downloaded: ~$downloaded${NC}"
        if [[ $skipped -gt 0 ]]; then
            echo -e "  ${YELLOW}⚠ Skipped (unavailable): ~$skipped${NC}"
        fi
        if [[ $errors -gt 0 ]]; then
            echo -e "  ${RED}✗ Errors: ~$errors${NC}"
            echo -e "  ${RED}  (see $ERROR_LOG for details)${NC}"
        fi
    fi
    
    highlight "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Save report
    {
        echo "Download Report - $(date)"
        echo "URL: $URL"
        echo "Mode: $DOWNLOAD_MODE"
        echo "Duration: ${duration}s"
        if [[ $IS_PLAYLIST -eq 1 ]]; then
            echo "Playlist: $PLAYLIST_TITLE"
            echo "Total: $PLAYLIST_COUNT"
            echo "Skipped: ~$skipped"
        fi
        echo "Result: $([ $result -eq 0 ] && echo 'SUCCESS' || echo 'PARTIAL/FAILED')"
    } > "$REPORT_FILE"
    
    # Log completion
    echo "Download completed: $(date), Duration: ${duration}s, Mode: $DOWNLOAD_MODE" >> "$LOG_FILE"
    
    return $result
}

# ============================================
# AUDIO DOWNLOAD MODE
# ============================================
if [[ "$DOWNLOAD_MODE" == "audio" ]]; then
    log "Downloading original audio and converting to MP3..."
    echo ""
    
    # Audio format options
    # ba[format_note*=original] - prioritize original audio
    # Falls back to ba (best audio) if no original found
    AUDIO_OPTS=(
        -f "ba[format_note*=original]/ba"
        --extract-audio
        --audio-format mp3
        --audio-quality 0
    )
    
    download_content "${AUDIO_OPTS[@]}"
    exit $?
fi

# ============================================
# VIDEO DOWNLOAD MODE
# ============================================
log "Downloading high quality video with original audio..."
echo ""

# Video format options
# bv*[ext=mp4]+ba[format_note*=original] - best mp4 video + original audio
# Falls back through various options to ensure something downloads
VIDEO_OPTS=(
    -f "bv*[ext=mp4]+ba[format_note*=original]/bv*[ext=mp4]+ba/bv*+ba[format_note*=original]/bv*+ba/best"
    --merge-output-format mp4
)

download_content "${VIDEO_OPTS[@]}"
exit $?
EOF

chmod +x "$BIN_DIR/termux-url-opener"
log_success "termux-url-opener script (v2) created and made executable"

# Verify installation
log_info "Verifying installation..."
if [[ -x "$BIN_DIR/termux-url-opener" ]]; then
    YT_DLP_VERSION=$(yt-dlp --version 2>/dev/null || echo "unknown")
    log_success "Installation complete!"
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo -e "${GREEN}  YouTube Downloader v2 Setup Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════${NC}"
    echo ""
    echo -e "✓ Tool: ${BLUE}yt-dlp v$YT_DLP_VERSION${NC}"
    echo -e "✓ Downloads: ${BLUE}$YT_DIR${NC}"
    echo ""
    echo -e "${WHITE}Features:${NC}"
    echo -e "  ${CYAN}📹 Video${NC}: High quality MP4 with Original Audio"
    echo -e "  ${MAGENTA}🎵 Audio${NC}: MP3 format (Original Language)"
    echo -e "  ${GREEN}📋 Playlist${NC}: Full playlist support"
    echo -e "  ${YELLOW}⚡ Smart${NC}: Skips unavailable videos automatically"
    echo ""
    echo -e "${WHITE}Edge Cases Handled:${NC}"
    echo -e "  - Private/Hidden videos → Skipped"
    echo -e "  - Deleted videos → Skipped"
    echo -e "  - Age-restricted → Skipped with warning"
    echo -e "  - Network errors → Auto-retry (10x)"
    echo -e "  - Rate limiting → Auto-delay between downloads"
    echo ""
    echo -e "✓ Logs: ${BLUE}$YT_DIR/.download.log${NC}"
    echo -e "✓ Errors: ${BLUE}$YT_DIR/.errors.log${NC}"
    echo ""
    echo -e "${CYAN}Share any YouTube video or playlist to download!${NC}"
    echo ""
else
    log_error "Installation verification failed"
    exit 1
fi
