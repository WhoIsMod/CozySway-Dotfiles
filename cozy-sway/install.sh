#!/usr/bin/env bash
# Installs the Cozy Dark Sway setup into $HOME, backing up existing files.
# Usage: ./install.sh [--deps]   (--deps installs packages with pacman first)
# Note: swww was renamed awww; install whichever your repos provide.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

if [[ "${1:-}" == "--deps" ]]; then
    sudo pacman -S --needed sway waybar fuzzel mako swaylock swayidle grim slurp wl-clipboard \
        brightnessctl playerctl pavucontrol pipewire pipewire-pulse pipewire-alsa wireplumber \
        xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr network-manager-applet power-profiles-daemon gamemode libnotify \
        kitty dolphin openvpn polkit-gnome zenity ttf-jetbrains-mono-nerd ttf-font-awesome curl obs-studio qt6-wayland bluez bluez-utils blueman pipewire-audio intel-media-driver libva-utils vulkan-intel gnome-themes-extra adwaita-icon-theme dconf gsettings-desktop-schemas alsa-utils alsa-ucm-conf sof-firmware pipewire-jack libpulse
    sudo systemctl enable --now bluetooth
    echo ">> Also install the wallpaper daemon: awww (formerly swww), e.g. 'paru -S awww' or 'pacman -S awww'"
    echo ">> Optional: swayfx (rounded corners + blur) instead of sway"
fi

cd "$HERE"
find .config .local -type f ! -name 'fx.conf.swayfx' ! -path '.config/obs-studio/*' | while read -r f; do
    dest="$HOME/$f"
    mkdir -p "$(dirname "$dest")"
    [[ -e "$dest" ]] && cp "$dest" "$dest.bak-$STAMP"
    cp "$f" "$dest"
done

# OBS "Cozy Stream" profile (never overwrites an existing one)
OBS_PROFILE="$HOME/.config/obs-studio/basic/profiles/Cozy_Stream"
if [[ ! -d "$OBS_PROFILE" ]]; then
    mkdir -p "$(dirname "$OBS_PROFILE")"
    cp -r .config/obs-studio/basic/profiles/Cozy_Stream "$OBS_PROFILE"
fi

# SwayFX effects only if SwayFX is installed; otherwise an empty include.
FX="$HOME/.config/sway/fx.conf"
[[ -e "$FX" ]] && cp "$FX" "$FX.bak-$STAMP"
if command -v swayfx >/dev/null 2>&1 || sway --version 2>/dev/null | grep -qi swayfx; then
    cp .config/sway/fx.conf.swayfx "$FX"
else
    echo "# plain Sway: no effects" > "$FX"
fi

# Hook the colour scheme into kitty
mkdir -p ~/.config/kitty
grep -qs 'cozy-dark.conf' ~/.config/kitty/kitty.conf || echo 'include cozy-dark.conf' >> ~/.config/kitty/kitty.conf

chmod +x ~/.local/bin/{desktop-mode,waybar-mode,waybar-weather,waybar-uptime,launch-game,wallpaper,openvpn-menu,openvpn-status,bluetooth-menu,waybar-obs,obs-open,audio-inputs,mic-menu}
mkdir -p ~/.local/state ~/Pictures/Wallpapers ~/.config/openvpn-gui
echo "Done. Put wallpapers in ~/Pictures/Wallpapers, then validate with: sway -C"
