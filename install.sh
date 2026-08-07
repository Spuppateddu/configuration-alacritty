#!/usr/bin/env bash
# Installs Alacritty + Courier Prime and links alacritty.toml into
# ~/.config/alacritty/ (the path Alacritty actually reads). Idempotent.
# Usage: ./install.sh [--dry-run]     (also honours DRY_RUN=true from the env)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Strict: a typo'd --dryrun must not silently do a real install.
case "${1:-}" in
    '')        ;;
    --dry-run) DRY_RUN=true ;;
    *)         printf 'Unknown argument: %s\nUsage: %s [--dry-run]\n' \
                   "$1" "${BASH_SOURCE[0]}" >&2
               exit 1 ;;
esac
if [[ $# -gt 1 ]]; then
    printf 'Unexpected extra arguments: %s\nUsage: %s [--dry-run]\n' \
        "${*:2}" "${BASH_SOURCE[0]}" >&2
    exit 1
fi
DRY_RUN="${DRY_RUN:-false}"

# ── Helpers ──────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    C_BLUE=$'\033[1;34m'; C_GREEN=$'\033[1;32m'; C_YELLOW=$'\033[1;33m'
    C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'; C_OFF=$'\033[0m'
else
    C_BLUE=''; C_GREEN=''; C_YELLOW=''; C_DIM=''; C_BOLD=''; C_OFF=''
fi
step()  { printf '%s▸%s %s\n' "$C_BLUE"  "$C_OFF" "$*"; }
ok()    { printf '%s✓%s %s\n' "$C_GREEN" "$C_OFF" "$*"; }
skip()  { printf '%s·%s %s%s%s\n' "$C_DIM" "$C_OFF" "$C_DIM" "$*" "$C_OFF"; }
warn()  { printf '%s!%s %s\n' "$C_YELLOW" "$C_OFF" "$*"; }
title() { printf '\n%s══ %s ══%s\n' "$C_BOLD" "$*" "$C_OFF"; }
would() { printf '%s  would %s:%s %s\n' "$C_DIM" "$1" "$C_OFF" "${*:2}"; }
run() {
    if [[ "$DRY_RUN" == true ]]; then
        would run "$*"
    else
        "$@"
    fi
}
has_cmd() { command -v "$1" >/dev/null 2>&1; }
# Needs a tty for the password prompt, or cached credentials — never hang.
can_sudo() { [[ -t 0 ]] || sudo -n true 2>/dev/null; }
apt_ensure() {
    local pkg missing=()
    has_cmd dpkg || { skip "not a dpkg system — skipping packages (${*})."; return 0; }
    for pkg in "$@"; do dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg"); done
    [[ ${#missing[@]} -eq 0 ]] && { skip "apt: nothing to install (${*})."; return 0; }
    if [[ "$DRY_RUN" == true ]]; then
        would install "${missing[*]}"; return 0
    fi
    if ! can_sudo; then
        warn "sudo unavailable (non-interactive) — skipped apt install: ${missing[*]}"; return 0
    fi
    step "apt: installing ${missing[*]}"
    sudo apt-get update -qq || warn "apt update reported errors — continuing."
    # Tolerated, not fatal: set -e would abort before the config is even linked.
    sudo apt-get install -y "${missing[@]}" ||
        warn "apt install failed (${missing[*]}) — continuing without them."
}
# link <src> <dst> — dst becomes a symlink to src, dst's parent created first.
link() {
    local src="$1" dst="$2"
    # Resolved, not string-compared: this repo is reachable both as the checkout
    # and via the ~/.alacritty symlink, and $REPO is whichever the caller used.
    if [[ -L "$dst" ]] && [[ "$(readlink -f "$dst" 2>/dev/null)" == "$(readlink -f "$src" 2>/dev/null)" ]]; then
        skip "${dst/#$HOME/\~} already linked."
        return
    fi
    run mkdir -p "$(dirname "$dst")"
    # A real file there is the user's own config — back it up, never delete it.
    # Only the first backup is kept, so re-runs can't litter or clobber it.
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        if [[ -e "$dst.backup" ]]; then
            warn "${dst/#$HOME/\~} exists — replacing (keeping earlier $dst.backup)"
        else
            warn "${dst/#$HOME/\~} exists — replacing (backup: ${dst/#$HOME/\~}.backup)"
            run cp "$dst" "$dst.backup"
        fi
    fi
    run ln -sfn "$src" "$dst"
    [[ "$DRY_RUN" == true ]] || ok "linked ${dst/#$HOME/\~}"
}

# ── Packages ─────────────────────────────────────────────────────────────────
title "Alacritty"

apt_ensure alacritty fontconfig curl unzip

# ── Font ─────────────────────────────────────────────────────────────────────
# Courier Prime is the only family alacritty.toml names; nothing sits behind it,
# so anything outside its coverage (icons, powerline, U+23F8/U+23F5) is tofu.
FONT_DIR="$HOME/.local/share/fonts"
FONTS_CHANGED=false

# NOT apt's fonts-courier-prime: it labels all four faces style=Light/weight=50,
# so bold and italic silently resolve to Regular. Upstream has no releases, hence
# the branch zip; the four ttf are copied out by name to keep sources/OTF/WOFF out.
if compgen -G "$FONT_DIR/CourierPrime*" >/dev/null 2>&1 \
   || fc-list : family 2>/dev/null | grep -qx "Courier Prime"; then
    skip "Courier Prime already installed."
elif ! has_cmd curl || ! has_cmd unzip; then
    warn "curl/unzip missing — skipped Courier Prime; the terminal will fall back to another face."
else
    url="https://github.com/quoteunquoteapps/CourierPrime/archive/refs/heads/master.zip"
    tmp="$(mktemp --suffix=.zip)"
    tmpdir="$(mktemp -d)"
    step "Installing Courier Prime (the terminal font)"
    run mkdir -p "$FONT_DIR"
    # Tested, not run bare: offline would otherwise abort before the config links.
    if run curl -fL --progress-bar -o "$tmp" "$url" \
       && run unzip -oq "$tmp" -d "$tmpdir" \
       && compgen -G "$tmpdir/CourierPrime-*/fonts/ttf/CourierPrime-*.ttf" >/dev/null 2>&1; then
        run cp -f "$tmpdir"/CourierPrime-*/fonts/ttf/CourierPrime-*.ttf "$FONT_DIR/"
        FONTS_CHANGED=true
        ok "Courier Prime installed."
    else
        warn "Could not install Courier Prime — the terminal will fall back to another face until a later run."
    fi
    # Not via run(): mktemp created these for real even under --dry-run.
    rm -rf "$tmp" "$tmpdir"
fi

# Both packages claim the same family name, so bold stops resolving predictably.
if has_cmd dpkg && dpkg -s fonts-courier-prime >/dev/null 2>&1; then
    warn "apt's fonts-courier-prime is installed and its faces are mislabelled (style=Light on all four)."
    warn "Remove it so bold resolves predictably:  sudo apt-get purge fonts-courier-prime"
fi

# ── Wiring ───────────────────────────────────────────────────────────────────
link "$REPO/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"

# Older versions linked a fontconfig fallback rule that no longer exists; the
# symlink survives as a dangling link fontconfig ignores. Removed only if it
# still points into this repo — a real file of that name is the user's.
stale_fc="$HOME/.config/fontconfig/conf.d/62-alacritty-mono-symbols.conf"
if [[ -L "$stale_fc" ]] && [[ "$(readlink "$stale_fc")" == *"/fontconfig/62-alacritty-mono-symbols.conf" ]]; then
    run rm -f "$stale_fc"
    [[ "$DRY_RUN" == true ]] || ok "removed stale ${stale_fc/#$HOME/\~}"
fi

# -r when fonts were added: plain -f has been seen leaving new files uncached.
if [[ "$FONTS_CHANGED" == true ]]; then
    run fc-cache -rf
else
    run fc-cache -f
fi

# ── Verify ───────────────────────────────────────────────────────────────────
# A missing font is not an error above — fontconfig just substitutes another.
if [[ "$DRY_RUN" == true ]]; then
    would run "fc-match check"
elif ! has_cmd fc-match; then
    warn "fc-match not available — skipped font verification."
else
    got="$(fc-match "Courier Prime" 2>/dev/null || true)"
    if [[ "$got" == *'"Courier Prime"'* ]]; then
        ok "text → Courier Prime"
    else
        warn "text → ${got:-nothing} (expected Courier Prime — fontconfig substituted)"
    fi
fi

# The toml is re-read on save; the font is resolved once at startup.
ok "Alacritty ready — restart open terminals if the font changed."
