{ pkgs, lib, ... }:

# Astrophotography stack shared by both hosts: INDI drivers (via udev) and the
# desktop apps used to capture/process (kstars, phd2, siril, gimp) plus rustdesk
# for remote control of the rig.
#
# ImPPG (post-processing/sharpening) lives in its own module, ./imppg.nix.
let
  # Siril 1.4's Python scripts (the .py from its script repository) run in a
  # venv that Siril builds itself and pip-installs numpy/scipy/PyQt6/sirilpy
  # into. Those manylinux wheels are dynamically linked and, on NixOS, fail to
  # find libstdc++/libz/Qt/X libs at import time. nix-ld does NOT help here: the
  # venv's python is a Nix binary, so its dlopen()s resolve via LD_LIBRARY_PATH,
  # not NIX_LD_LIBRARY_PATH. So we wrap Siril to export this library path to the
  # python child it spawns.
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
  imports = [ ./imppg.nix ];

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
    rustdesk-flutter
    indi-full
    indi-3rdparty.indi-toupbase
    indi-3rdparty.indi-playerone

    # Needed on PATH so Siril can create its Python venv for .py scripts.
    python3
  ];

  # Serial access for INDI-controlled mounts/focusers.
  users.users.alexandre.extraGroups = [ "dialout" ];
}
