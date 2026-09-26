# astronix

NixOS flake for two astrophotography machines.

## Hosts

| Host | hostName | Role |
| --- | --- | --- |
| `astronix` | `astronomix` | The rig. Headless Plasma 6 on X11, SDDM autologin, xrdp, a fake EDID for the virtual display, a WiFi hotspot fallback, and the `junos-web` capture app. |
| `dev` | `inix` | The workstation. GNOME, DisplayLink dock, corporate CA and VPN bits, dev tooling. |

Both run user `alexandre` and share the astro stack: INDI, KStars, PHD2, Siril.

## Layout

```
flake.nix              inputs (nixpkgs fork, home-manager, junos, catppuccin) + the two hosts
justfile               rebuild/update/gc recipes
modules/
  common.nix           base config; imports the modules below
  locale.nix           timezone + locale
  audio.nix            PipeWire
  input.nix            QMK, keyd esc<->caps, qwerty-fr layout
  home.nix             home-manager + Catppuccin, Ghostty, Zellij
  theme.nix            light/dark settings, shared by both layers
  darkman.nix          rebuilds into the other theme at sunrise/sunset (dev)
  keyring.nix          keyring opt-out
  zsh.nix              zsh + oh-my-zsh
  astro.nix            astro stack (INDI + apps)
  imppg.nix            ImPPG, built from source
  gsc.nix              GSC star catalog, for INDI's CCD Simulator
  graxpert.nix         GraXpert, from the upstream bundle
  autostakkert.nix     AutoStakkert!4, under Wine (dev)
  desktop-plasma.nix   headless Plasma + xrdp (astronix)
  desktop-gnome.nix    GNOME (dev)
  docker.nix           Docker (dev)
  wine.nix             Wine + bottles (dev)
  printing.nix         CUPS + the office printer (dev)
  syncthing.nix        services.astronix.syncthing (dev)
  wifi-hotspot.nix     services.astronix.wifi (astronix)
hosts/
  astronix/            configuration.nix + hardware-configuration.nix
  dev/                 configuration.nix + hardware-configuration.nix + displaylink.nix + certs/
```

Each host's `configuration.nix` only composes modules and adds what is unique
to that machine.

## Rebuild

`just` is installed on every host (see `modules/common.nix`); run it from this
repo. Recipes default to the host you are on — `astronomix` maps to `astronix`,
anything else to `dev` — and take a flake attribute for any other:

```sh
just              # list every recipe
just switch       # rebuild + activate this host
just switch dev-dark
just diff         # build, then show what would change versus the running system
just check        # evaluate every host without building
just update       # bump every flake input
just gc 14        # drop generations older than 14 days, then collect garbage
```

The raw command still works:

```sh
sudo nixos-rebuild switch --flake .#astronix   # the rig
sudo nixos-rebuild switch --flake .#dev        # the workstation
```

`update` is also a shell alias for `sudo nixos-rebuild switch` (see `modules/zsh.nix`).
