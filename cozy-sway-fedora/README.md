# Cozy Dark Sway (Fedora edition)

A cozy dark Wayland desktop built on **Sway**, styled after a navy and lavender
KDE-style reference, with:

- **Waybar** bottom panel (workspace dots, dock-style launchers, coloured icons)
- **PipeWire / WirePlumber** audio (`wpctl` keybinds, volume module)
- **swww / awww** wallpaper manager with transitions
- **Game Mode / Business Mode** toggle (GameMode, power profiles, effects on/off)
- **OpenVPN tray-style icon** (pick a `.ovpn`, connect, disconnect)
- Matching themes for fuzzel, mako, swaylock and kitty

> Sway is Wayland-only. `swww`/`awww` also needs Wayland, so none of this runs in
> an X11 session. Pick **Sway** at your login screen (or run
> `sway --unsupported-gpu` from a TTY if you use the proprietary NVIDIA driver).

## Install (Fedora 42 or newer)

Works on the **Fedora Sway Spin** (Sway is already installed) or any Fedora where you
add Sway.

```
unzip cozy-sway-fedora.zip && cd cozy-sway-fedora
bash install.sh --deps      # --deps installs packages with dnf first
sway -C                     # validate the config
```

Then log out and choose the **Sway** session at the login screen. `install.sh`
backs up any file it replaces as `<file>.bak-<timestamp>` (including the Spin's default
`~/.config/sway/config`).

What `--deps` does beyond `dnf install`:

- installs a polkit agent (needed for the VPN password prompt) and Font Awesome
- installs **OBS Studio**: the RPM Fusion package if that repo is enabled, otherwise the
  Flathub build (the OBS button and Stream mode launch either one)
- downloads **JetBrainsMono Nerd Font** into `~/.local/share/fonts`
- installs the wallpaper daemon **awww** (formerly swww) from dnf if packaged, otherwise
  builds it with `cargo`. If that fails, install it from the project's page and put the
  binaries in `~/.local/bin`
- enables Bluetooth and the PipeWire user services

Notes for Fedora:

- Packages that aren't in your enabled repos are listed and skipped. Intel hardware
  video encoding (VAAPI) needs `intel-media-driver`; if `vainfo` shows no H264 encode
  entry and the package is missing, enable RPM Fusion (free and nonfree), install it,
  and use RPM Fusion's `obs-studio`.
- **SwayFX** (rounded corners and blur) isn't in the main repos. Plain Sway works fine;
  effects only apply if you install SwayFX yourself.
- Fedora's Sway Spin sets power profiles through `tuned-ppd`, which provides the same
  `powerprofilesctl` interface the Game and Stream modes use.
- If Bluetooth audio devices don't show up as audio outputs, install PipeWire's
  Bluetooth plugin for your release.

## Keybinds (`$mod` = Super)

| Keys | Action |
|---|---|
| `$mod+Return` | Terminal (kitty) |
| `$mod+d` | App launcher (fuzzel) |
| `$mod+b` / `$mod+e` | Browser / Files (Dolphin) |
| `$mod+Shift+q` | Close window |
| `$mod+Shift+c` | Reload config |
| `$mod+h/j/k/l` or arrows | Focus (add `Shift` to move the window) |
| `$mod+1..0` | Switch workspace (`Shift` to move window there) |
| `$mod+v` / `$mod+s` | Split vertical / horizontal |
| `$mod+f` | Fullscreen |
| `$mod+space` | Toggle floating |
| `$mod+r` | Resize mode (`Esc` to leave) |
| `$mod+g` | **Toggle Game / Business mode** |
| `$mod+Shift+g` | Enable Game mode and launch Steam/Lutris |
| `$mod+Shift+b` | Business mode |
| `$mod+m` | Mode menu (modes, lock, logout, reboot, shutdown) |
| `$mod+Escape` | System mode (g/b/l/q) |
| `$mod+w` / `$mod+Shift+w` | Next / random wallpaper |
| `$mod+Shift+v` | VPN menu |
| `$mod+Shift+t` | Bluetooth menu |
| `$mod+Shift+m` | Microphone / input device menu |
| `$mod+Shift+o` | **Stream mode** (opens OBS, silences notifications) |
| `$mod+o` | Focus / launch OBS Studio |
| `$mod+Shift+i` | Hide / show the panel (privacy while capturing the whole monitor) |
| `$mod+n` / `$mod+Shift+n` | Volume control / network editor |
| `$mod+Shift+x` | Lock screen |
| `Print` / `Shift+Print` | Screenshot region / full screen |

Volume, mute, media and brightness keys work via `wpctl`, `playerctl` and
`brightnessctl`.

## The panel

- **Left:** app grid (fuzzel), workspace dots, window title
- **Centre:** clickable launchers: terminal, files, browser, Discord, Spotify, Steam
- **Right:** now playing, **OBS button**, mode pill, idle inhibitor, clock, weather, CPU, RAM,
  uptime, **VPN**, **Bluetooth**, volume, network, tray, power menu

Click targets: mode pill toggles Game/Business (right-click: menu); volume opens
`pavucontrol` (right-click: mute); clock click swaps to the date; power button
opens the mode menu.

## Game / Business mode

| | Game | Business |
|---|---|---|
| GameMode client | running (`gamemoderun sleep infinity`) | stopped |
| Power profile | performance | balanced |
| Compositor effects (SwayFX) | blur, shadows, rounded corners off | on |

Config for GameMode is in `~/.config/gamemode.ini`. For individual Steam games you
can also use `gamemoderun %command%` in the launch options. Test with
`gamemoded -t`.

## Wallpapers

Put images in `~/Pictures/Wallpapers` (override with `WALLPAPER_DIR`).

```
~/.local/bin/wallpaper init            # restore last (runs on login)
~/.local/bin/wallpaper next | random
~/.local/bin/wallpaper set /path/to/img.png
```

You never need to start `awww-daemon` by hand; the script starts it. If it
reports it can't connect to a Wayland socket, you aren't inside a Sway session.

## Audio

PipeWire + WirePlumber + `pipewire-pulse`. If there's no sound:

```
systemctl --user enable --now pipewire pipewire-pulse wireplumber
wpctl status                  # default sink has a *
wpctl set-default <id>        # pick the right output (not HDMI on the GPU)
wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
speaker-test -c 2 -t wav -l 1
```

## OpenVPN tray-style icon

The shield icon on the right of the panel works like OpenVPN GUI on Windows.

- **Grey** disconnected, **yellow** connecting, **green** connected (the tooltip
  shows the config name and tunnel IP)
- **Left-click:** menu listing your configs (`●` marks the active one), plus
  Import config, Disconnect, Open folder, Show log
- **Right-click:** disconnect

Put `.ovpn` files in `~/.config/openvpn-gui/`, run `openvpn-menu import /path/to/file.ovpn`, or use **Import config**, which also
copies cert/key files referenced next to the config. Connecting runs
`openvpn` through `pkexec`, so a polkit prompt appears (an agent starts with Sway).
If a config needs a username and password you'll be prompted for them; they are
kept in a temporary file in `$XDG_RUNTIME_DIR` and deleted once the tunnel is up.

Needs `openvpn`, `polkit-gnome` and `zenity` (or `kdialog`).

## Streaming with OBS Studio

**Stream mode** (`$mod+Shift+o`, or the Mode menu, or right-click the OBS button):
GameMode on, performance power profile, blur/shadows off (less GPU load), OBS launched
if it isn't running, and notifications silenced (mako `do-not-disturb`, so nothing
private pops up on stream). Business mode turns notifications back on. While OBS is
open, Sway won't lock or blank the screen (`inhibit_idle`), and OBS opens on workspace 9.

**Screen capture:** in OBS add *Screen Capture (PipeWire)*. A fuzzel picker
(from `xdg-desktop-portal-wlr`) asks which monitor to share. The wlroots portal captures
monitors, not individual windows. For game-only capture, `obs-vkcapture` is an option
(package availability varies by distro). If you capture the whole monitor,
hide the panel with `$mod+Shift+i`, since it shows weather, Wi-Fi and VPN details.

**Encoder (Intel laptop):** the installer adds an OBS profile called **Cozy Stream**
(1080p, 30 fps, x264 `veryfast`, CBR 6000 kbps, 2 s keyframes; a safe starting point
for Twitch, raise the bitrate for YouTube). For much lower CPU load and heat, switch to
Intel hardware encoding: *Settings -> Output -> Streaming -> Encoder* ->
**FFmpeg VAAPI H.264 (hardware)**, device `/dev/dri/renderD128`, CBR 6000 kbps. Check
that VA-API works first with `vainfo` (look for `VAEntrypointEncSlice` or
`EncSliceLP` under H264). With VAAPI you can usually raise the output to 60 fps.
Installed drivers: `intel-media-driver` (Fedora: from RPM Fusion nonfree if your repos lack it) for
recent Intel graphics. Older Intel chips (before Broadwell) need `libva-intel-driver` /
`i965-va-driver`. The profile is not overwritten if it already exists.

**Audio routing:** PipeWire drop-in config creates three virtual sinks: *Stream Game*,
*Stream Music*, *Stream Chat*. In `pavucontrol` -> Playback, send each app (game,
Spotify, Discord) to one of them; you still hear everything in your headphones. In
OBS add an *Audio Input Capture (PulseAudio)* source per sink and pick
**Monitor of Stream Game** (etc.), plus your microphone (add OBS's *Noise Suppression*
filter on the mic). Mute OBS's *Desktop Audio* so nothing is captured twice, which
gives you separate volume sliders per source. Restart PipeWire once to load the sinks:
`systemctl --user restart pipewire pipewire-pulse wireplumber`.

**Virtual camera (optional):** needs the `v4l2loopback` kernel module
(`akmod-v4l2loopback` from RPM Fusion on Fedora). Load it with
`sudo modprobe v4l2loopback exclusive_caps=1 card_label="OBS Camera"`.

## Bluetooth

The Bluetooth icon on the panel turns grey when off and green with a device count when
connected (the tooltip lists the devices and battery levels). Left-click opens the menu:
connect or disconnect a paired device, **Pair new device** (10 s scan), turn Bluetooth
on or off, and open the full manager (`blueman`). Right-click toggles power. Bluetooth
audio goes through PipeWire; after connecting headphones, pick them in `pavucontrol`
or the volume control. Devices that need a PIN may need `blueman-manager` to pair.
Needs the `bluetooth` service running (the installer enables it).

## Microphones and aux (3.5 mm / inline) inputs

The microphone icon next to the volume on the panel shows the default input (red when
muted). Left-click lists every input PipeWire can see, lets you pick the default (running
recordings, such as OBS or Discord, are moved to it) and has shortcuts for muting, the
mixer's Input Devices tab, a **Fix / rescan** run and diagnostics. Right-click mutes,
scroll changes the input volume, and `$mod+Shift+m` opens the same menu.

All inputs go through PipeWire, so recording software sees them too: OBS and Audacity
(PulseAudio sources), ALSA apps via `pipewire-alsa`, and JACK apps via `pipewire-jack`
(run them with `pw-jack`).

### Studio / condenser microphones (for example the Music D.J. M-800)

What works depends on the plug on the mic's cable, so check it first:

- **USB:** plug it straight into a USB port. It shows up as its own sound card in
  `lsusb`, `arecord -l` and pavucontrol -> Input Devices (not under the laptop's jack).
  `audio-inputs fix` switches its card to an input profile if it is stuck on "Off".
- **3.5 mm plug:** laptops with a single headset (combo) jack expect a 4-pole headset plug.
  A normal 3-pole mic plug usually gives no signal there; use a dedicated mic input, a
  USB sound card, or a TRS-to-TRRS adapter. Condenser mics also need power from the jack.
- **XLR:** condenser mics with an XLR plug need 48 V phantom power, which a laptop can't
  supply. Use a USB audio interface with a +48V switch.

If `audio-inputs status` shows inputs named `...pro-input-0` (or the card is on **Pro Audio** in
pavucontrol -> Configuration), the card is in the raw professional profile, with no jack or
port switching. `audio-inputs fix` switches it to a normal profile when one is available.

`audio-inputs status` ends with a **Verdict** that says whether the jack sees a
microphone or only headphones. Condenser mics are quiet on laptop inputs. Raise the gain with `alsamixer -c 0`
(F4, Capture and Mic Boost) or in pavucontrol, and keep the input volume below 100%
to avoid distortion.

If your inline/headset mic doesn't show up:

1. In `pavucontrol` -> **Input Devices**, set *Show:* to **All Input Devices**
   (the default filter hides some inputs) and check the port dropdown for
   *Headset Microphone* / *Microphone*.
2. Plug the headset in and run `~/.local/bin/audio-inputs status`. It lists
   PipeWire inputs, ALSA capture hardware, the kernel's jack-detection state and
   firmware errors. `audio-inputs fix` restarts WirePlumber, switches cards to an
   input-capable profile, enables ALSA capture controls, unmutes inputs and sets a real
   default input (it also sets input volumes to 80%).
3. Intel laptops usually need `alsa-sof-firmware` and `alsa-ucm` (installed by
   `install.sh --deps`); reboot after installing them.
4. Hardware: a headset with a built-in mic needs a 4-pole (TRRS) plug and a combo jack.
   A headphone-only jack can't take a mic, and CTIA/OMTP wiring mismatches give no mic.
   If the jack values in `audio-inputs status` never change when you plug something in,
   the kernel isn't detecting it; `hdajackretask` (package `alsa-tools`) can retask the
   pin.

## Files

```
~/.config/sway/config            main config
~/.config/sway/fx.conf           SwayFX effects (empty on plain Sway)
~/.config/waybar/{config.jsonc,style.css}
~/.config/{fuzzel,mako,swaylock}/  themes
~/.config/kitty/cozy-dark.conf   colours (included from kitty.conf)
~/.config/gamemode.ini
~/.config/pipewire/pipewire.conf.d/10-stream-sinks.conf   virtual streaming sinks
~/.config/xdg-desktop-portal-wlr/config                   OBS screen-share picker
~/.config/obs-studio/basic/profiles/Cozy_Stream/          OBS profile
~/.local/bin/
    desktop-mode                 game/business controller
    waybar-mode, waybar-weather, waybar-uptime
    wallpaper                    swww/awww manager
    openvpn-menu, openvpn-status VPN module
    bluetooth-menu               Bluetooth menu (bluetoothctl + fuzzel)
    mic-menu, audio-inputs       input device menu / mic diagnostics and fix
    waybar-obs, obs-open         OBS panel button / focus-or-launch
    launch-game
```

## Palette

| | | |
|---|---|---|
| bg `#1a1d2b` | surface `#2c3147` | text `#d9deee` |
| blue `#8aa4ff` | lavender `#b4a0ff` | cyan `#8ad6e0` |
| green `#a9d9a0` | yellow `#ecd08a` | red `#ef8e9a` |

## Troubleshooting

- **Waybar missing at login:** `exec_always` lines must not contain a bare `;`
  (Sway treats it as a command separator); the config uses
  `sh -c 'pkill -x waybar; exec waybar'`. To see errors run
  `pkill waybar; waybar -l debug`.
- **`awww-daemon` can't find the Wayland socket:** you aren't in a Wayland
  session. Log in to Sway.
- **File picker doesn't open in browsers:** needs `xdg-desktop-portal` +
  `xdg-desktop-portal-gtk`, the portal config in
  `~/.config/xdg-desktop-portal/sway-portals.conf`, and the
  `dbus-update-activation-environment` line in the Sway config. Then run
  `systemctl --user restart xdg-desktop-portal xdg-desktop-portal-gtk` (or log out
  and back in). Check logs with `journalctl --user -u xdg-desktop-portal -b`.
- **File dialog (upload window) too big, white, or buttons off-screen:** the dark
  GTK theme lives in `~/.config/gtk-3.0` and `gtk-4.0`, and Sway rules in the config
  resize and centre file dialogs to 60% x 70% of the screen. If a dialog is still
  oversized, reset its remembered size:
  `gsettings reset-recursively org.gtk.Settings.FileChooser; gsettings reset-recursively org.gtk.gtk4.Settings.FileChooser`,
  then `systemctl --user restart xdg-desktop-portal xdg-desktop-portal-gtk`.
  For a Dolphin-style (KDE) dialog instead, install `xdg-desktop-portal-kde` and add
  `org.freedesktop.impl.portal.FileChooser=kde` under `[preferred]` in
  `~/.config/xdg-desktop-portal/sway-portals.conf`.
- **Empty box instead of an icon:** your Nerd Font lacks that glyph; install
  `ttf-jetbrains-mono-nerd` and `ttf-font-awesome`.
- **Laptop:** the panel has battery and brightness modules (scroll on the brightness
  icon to adjust). Stream mode warns when you are on battery; plug in for streaming.
- **Weather:** location is detected by IP via wttr.in; edit `waybar-weather` to
  pin a city.
- **NVIDIA only:** Sway needs `--unsupported-gpu` (not needed on Intel graphics).
- **GTK/Qt apps (e.g. Dolphin) don't match the theme:** set a dark theme with
  `nwg-look` or `kvantum`.
