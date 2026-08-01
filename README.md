# astronix

NixOS flake configuration for two astrophotography machines.

## Hosts

| Host | hostName | Role |
| --- | --- | --- |
| `astronix` | `astronomix` | Headless astrophoto rig — Plasma 6 on X11 with SDDM autologin and xrdp remote access, a fake-EDID virtual display, WiFi hotspot fallback, and the `junos-web` capture web app. |
| `dev` | `dev` | GNOME workstation — trimmed-down GNOME desktop, DisplayLink dock, corporate CA/VPN bits, and dev tooling. |

Both run user `alexandre` and share the astrophotography stack (INDI drivers, KStars, PHD2, Siril).

## Layout

```
flake.nix              inputs (forked nixpkgs, home-manager, rekos-web, catppuccin) + the two hosts
modules/
  common.nix           base config; imports the per-concern modules below
  locale.nix           timezone + locale
  audio.nix            PipeWire
  input.nix            keyboard: QMK, keyd esc<->caps, qwerty-fr layout
  home.nix             home-manager wiring + Catppuccin/Ghostty user config
  zsh.nix              zsh + oh-my-zsh
  astro.nix            shared astrophotography stack (INDI + apps)
  desktop-plasma.nix   headless Plasma/xrdp desktop (astronix)
  desktop-gnome.nix    GNOME desktop (dev)
  wifi-hotspot.nix     services.astronix.wifi module (astronix)
hosts/
  astronix/            configuration.nix + hardware-configuration.nix
  dev/                 configuration.nix + hardware-configuration.nix + displaylink.nix + certs/
```

Each host's `configuration.nix` is a thin composition: it imports `common.nix`, `astro.nix`,
its desktop module, and any host-specific modules, then adds only what is unique to that machine.

## Rebuild

```sh
sudo nixos-rebuild switch --flake .#astronix   # on the rig
sudo nixos-rebuild switch --flake .#dev         # on the workstation
```

`update` is aliased to `sudo nixos-rebuild switch` in the shell (see `modules/zsh.nix`).
