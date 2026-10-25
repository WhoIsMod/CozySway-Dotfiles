#!/usr/bin/env bash
# Cozy Dark Sway for Debian 13 (trixie). Debian 12 lacks some packages (e.g. fuzzel).
# Usage: ./install.sh [--deps]   (--deps installs packages with apt first)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

have_pkg() { apt-cache show "$1" >/dev/null 2>&1; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }

install_deps() {
    sudo apt-get update
    local want=(sway waybar fuzzel mako-notifier swaylock swayidle grim slurp wl-clipboard
        brightnessctl playerctl pavucontrol pipewire pipewire-pulse pipewire-alsa wireplumber
        xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-utils
        network-manager network-manager-gnome power-profiles-daemon gamemode libnotify-bin
        kitty dolphin fonts-font-awesome curl xz-utils openvpn zenity dbus dbus-user-session
        obs-studio qt6-wayland bluez libspa-0.2-bluetooth blueman rfkill
        intel-media-va-driver vainfo mesa-vulkan-drivers
        gnome-themes-extra adwaita-icon-theme dconf-gsettings-backend libglib2.0-bin gsettings-desktop-schemas
        alsa-utils alsa-ucm-conf firmware-sof-signed pipewire-jack pulseaudio-utils)
    local ok=() missing=() p
    for p in "${want[@]}"; do
        if have_pkg "$p"; then ok+=("$p"); else missing+=("$p"); fi
    done
    sudo apt-get install -y "${ok[@]}"
    (( ${#missing[@]} )) && echo ">> Not available on this release: ${missing[*]}"

    # pkexec (package name differs between releases)
    for p in pkexec policykit-1; do
        if have_pkg "$p"; then sudo apt-get install -y "$p"; break; fi
    done
    # a polkit authentication agent: first one available
    for p in policykit-1-gnome polkit-kde-agent-1 mate-polkit lxpolkit; do
        if have_pkg "$p"; then sudo apt-get install -y "$p"; break; fi
    done

    # JetBrainsMono Nerd Font (not in Debian repos)
    if ! fc-list 2>/dev/null | grep -qi 'JetBrainsMono Nerd'; then
        echo ">> Installing JetBrainsMono Nerd Font"
        tmp="$(mktemp -d)"
        if curl -fL -o "$tmp/jb.tar.xz" \
            https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz; then
            mkdir -p ~/.local/share/fonts/JetBrainsMonoNerd
            tar -xJf "$tmp/jb.tar.xz" -C ~/.local/share/fonts/JetBrainsMonoNerd
            fc-cache -f
        else
            echo ">> Font download failed; install a Nerd Font manually."
        fi
        rm -rf "$tmp"
    fi

    # Wallpaper daemon: awww (formerly swww)
    if ! have_cmd awww && ! have_cmd swww && [[ ! -x ~/.cargo/bin/awww && ! -x ~/.cargo/bin/swww ]]; then
        for p in awww swww; do
            if have_pkg "$p"; then sudo apt-get install -y "$p"; break; fi
        done
    fi
    if ! have_cmd awww && ! have_cmd swww && [[ ! -x ~/.cargo/bin/awww && ! -x ~/.cargo/bin/swww ]]; then
        echo ">> Building the wallpaper daemon with cargo (takes a few minutes)"
        sudo apt-get install -y cargo pkg-config liblz4-dev build-essential
        cargo install --locked awww || cargo install --locked swww || \
            echo ">> Could not build it. Get awww (formerly swww) from its project page and put it in ~/.local/bin."
    fi

    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
    sudo systemctl enable --now bluetooth 2>/dev/null || true
}

[[ "${1:-}" == "--deps" ]] && install_deps

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

# SwayFX effects only if SwayFX is installed (not packaged in Debian); otherwise empty include.
FX="$HOME/.config/sway/fx.conf"
[[ -e "$FX" ]] && cp "$FX" "$FX.bak-$STAMP"
if have_cmd swayfx || sway --version 2>/dev/null | grep -qi swayfx; then
    cp .config/sway/fx.conf.swayfx "$FX"
else
    echo "# plain Sway: no effects" > "$FX"
fi

mkdir -p ~/.config/kitty
grep -qs 'cozy-dark.conf' ~/.config/kitty/kitty.conf || echo 'include cozy-dark.conf' >> ~/.config/kitty/kitty.conf

chmod +x ~/.local/bin/{desktop-mode,waybar-mode,waybar-weather,waybar-uptime,launch-game,wallpaper,openvpn-menu,openvpn-status,bluetooth-menu,waybar-obs,obs-open,audio-inputs,mic-menu,polkit-agent}
mkdir -p ~/.local/state ~/Pictures/Wallpapers ~/.config/openvpn-gui
echo "Done. Put wallpapers in ~/Pictures/Wallpapers, validate with: sway -C"
echo "Then log out and pick the Sway session at the login screen."
