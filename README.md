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
justfile               rebuild/update/gc recipes, shared by both hosts
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
  docker.nix           Docker engine + CLI, user in docker group (dev)
  wifi-hotspot.nix     services.astronix.wifi module (astronix)
hosts/
  astronix/            configuration.nix + hardware-configuration.nix
  dev/                 configuration.nix + hardware-configuration.nix + displaylink.nix + certs/
```

Each host's `configuration.nix` is a thin composition: it imports `common.nix`, `astro.nix`,
its desktop module, and any host-specific modules, then adds only what is unique to that machine.

## Rebuild

`just` is installed on every host (see `modules/common.nix`); run it from this repo.
Recipes default to the host you are on — `astronomix` maps to `astronix`, anything
else to `dev` — and take an explicit flake attribute when you want another:

```sh
just              # list every recipe
just switch       # rebuild + activate this host
just switch dev-dark
just diff         # build, then show what would change versus the running system
just check        # evaluate every host without building
just update       # bump every flake input
just gc 14        # drop generations older than 14 days, then collect garbage
```

The underlying command is unchanged if you prefer it raw:

```sh
sudo nixos-rebuild switch --flake .#astronix   # on the rig
sudo nixos-rebuild switch --flake .#dev         # on the workstation
```

`update` is aliased to `sudo nixos-rebuild switch` in the shell (see `modules/zsh.nix`).
