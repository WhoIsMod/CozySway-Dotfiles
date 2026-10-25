#!/usr/bin/env bash
# Cozy Dark Sway for Fedora 42+ (dnf5): Sway Spin or any Fedora with Sway.
# Usage: ./install.sh [--deps]   (--deps installs packages with dnf first)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
STAMP="$(date +%Y%m%d-%H%M%S)"

have_pkg() { rpm -q "$1" >/dev/null 2>&1 || dnf repoquery -q "$1" 2>/dev/null | grep -q .; }
have_cmd() { command -v "$1" >/dev/null 2>&1; }

install_deps() {
    local want=(sway waybar fuzzel mako swaylock swayidle grim slurp wl-clipboard
        brightnessctl playerctl pavucontrol
        pipewire pipewire-pulseaudio pipewire-alsa pipewire-jack-audio-connection-kit
        wireplumber pulseaudio-utils alsa-utils alsa-ucm alsa-sof-firmware
        xdg-desktop-portal xdg-desktop-portal-gtk xdg-desktop-portal-wlr xdg-utils
        NetworkManager network-manager-applet nm-connection-editor polkit
        gamemode libnotify kitty dolphin openvpn zenity curl xz
        qt6-qtwayland bluez blueman
        gnome-themes-extra adwaita-icon-theme dconf glib2 dbus-tools
        libva-utils mesa-vulkan-drivers libva-intel-media-driver intel-media-driver)
    local ok=() missing=() p
    for p in "${want[@]}"; do
        if have_pkg "$p"; then ok+=("$p"); else missing+=("$p"); fi
    done
    sudo dnf install -y "${ok[@]}"
    (( ${#missing[@]} )) && echo ">> Not available in your enabled repos: ${missing[*]}"

    # polkit authentication agent (needed for the VPN password prompt)
    for p in polkit-gnome lxqt-policykit; do
        if have_pkg "$p"; then sudo dnf install -y "$p"; break; fi
    done
    # Font Awesome (package name varies by release)
    for p in fontawesome-fonts-all fontawesome-6-free-fonts fontawesome-fonts; do
        if have_pkg "$p"; then sudo dnf install -y "$p"; break; fi
    done
    # Power profiles: Fedora may use tuned-ppd, which provides the same API
    rpm -q tuned-ppd >/dev/null 2>&1 || rpm -q power-profiles-daemon >/dev/null 2>&1 \
        || sudo dnf install -y power-profiles-daemon || true

    # OBS Studio: RPM Fusion package if enabled, otherwise the Flathub build
    if ! have_cmd obs; then
        if have_pkg obs-studio; then
            sudo dnf install -y obs-studio
        elif have_cmd flatpak; then
            echo ">> obs-studio isn't in your enabled repos; installing OBS from Flathub"
            flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
            flatpak install --user -y flathub com.obsproject.Studio || echo ">> OBS install failed; see the README."
        fi
    fi

    # JetBrainsMono Nerd Font (not in the Fedora repos)
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

    # Wallpaper daemon: awww (formerly swww), built with cargo if not packaged
    if ! have_cmd awww && ! have_cmd swww && [[ ! -x ~/.cargo/bin/awww && ! -x ~/.cargo/bin/swww ]]; then
        for p in awww swww; do
            if have_pkg "$p"; then sudo dnf install -y "$p"; break; fi
        done
    fi
    if ! have_cmd awww && ! have_cmd swww && [[ ! -x ~/.cargo/bin/awww && ! -x ~/.cargo/bin/swww ]]; then
        echo ">> Building the wallpaper daemon with cargo (takes a few minutes)"
        sudo dnf install -y cargo gcc pkgconf-pkg-config lz4-devel
        cargo install --locked awww || cargo install --locked swww || \
            echo ">> Could not build it. Get awww (formerly swww) from its project page and put it in ~/.local/bin."
    fi

    sudo systemctl enable --now bluetooth 2>/dev/null || true
    systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
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

# SwayFX effects only if SwayFX is installed (not in the Fedora repos); otherwise empty include.
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
