{ pkgs, lib, ... }:

# Astro stack for both hosts: INDI drivers via udev, the capture and processing
# apps (kstars, phd2, siril, gimp), and rustdesk to drive the rig remotely.
#
# ImPPG has its own module, ./imppg.nix. So does the GSC star catalog,
# ./gsc.nix: INDI's CCD Simulator needs it, but it weighs ~235 MB and only
# serves simulated sessions, so move that import to hosts/dev to spare the rig.
let
  # Siril 1.4 runs its Python scripts in a venv it builds itself, with
  # numpy/scipy/PyQt6/sirilpy pip-installed into it. Those wheels are
  # dynamically linked and can't find libstdc++/libz/Qt/X at import time.
  # nix-ld does not help: the venv's python is a Nix binary, so it reads
  # LD_LIBRARY_PATH, not NIX_LD_LIBRARY_PATH. Hence the wrapper below, which
  # hands this path to the python child.
  sirilVenvLibs = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    glib
    # PyQt6 (GUI scripts such as HDR_multiscale, VeraLux)
    fontconfig
    freetype
    dbus
    libGL
    libxkbcommon
    libxcb-cursor
    xorg.libX11
    xorg.libxcb
    xorg.libXext
    xorg.libXrender
    xorg.xcbutil
    xorg.xcbutilwm
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
  ];

  siril = pkgs.symlinkJoin {
    name = "siril-venv-wrapped";
    paths = [ pkgs.siril ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for b in siril siril-cli; do
        if [ -e "$out/bin/$b" ]; then
          wrapProgram "$out/bin/$b" \
            --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath sirilVenvLibs}"
        fi
      done
    '';
  };
in
{
  imports = [ ./imppg.nix ./gsc.nix ];

  services.udev.packages = [
    pkgs.indi-full
    pkgs.indi-3rdparty.indi-toupbase
    pkgs.indi-3rdparty.indi-playerone
  ];

  environment.systemPackages = with pkgs; [
    kstars
    phd2
    siril
    gimp
    nomacs # fast viewer for captured and stacked frames
    rustdesk-flutter
    indi-full
    indi-3rdparty.indi-toupbase
    indi-3rdparty.indi-playerone

    # On PATH so Siril can build its venv for .py scripts.
    python3
  ];

  # Serial access for INDI-controlled mounts/focusers.
  users.users.alexandre.extraGroups = [ "dialout" ];
}
