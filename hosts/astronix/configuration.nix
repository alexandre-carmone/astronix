{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./headless.nix
    ../../modules/common.nix
  ];

  networking.hostName = "nixos";

  # Force the HDMI connector to be treated as always-connected so that
  # Xorg starts a real :0 session even without a monitor plugged in.
  # When a monitor is plugged in, it displays the same :0 session.
  # Replace HDMI-A-1 with the actual connector on this host. Discover via:
  #   for c in /sys/class/drm/card*-*; do echo "$(basename $c): $(cat $c/status)"; done
  boot.kernelParams = [
    "video=HDMI-A-1:1920x1080@60e"
    "video=HDMI-A-2:1920x1080@60e"
    "video=HDMI-1:1920x1080@60e"
    "video=HDMI-2:1920x1080@60e"
    "video=DP-1:1920x1080@60e"
    "video=DP-2:1920x1080@60e"
    "video=VGA-1:1920x1080@60e"
    "video=eDP-1:1920x1080@60e"
  ];

  services.printing.enable = true;
  programs.firefox.enable = true;

  users.users.alexandre.packages = with pkgs; [
    kdePackages.kate
  ];

  environment.systemPackages = with pkgs; [
    ghostty
    rustdesk-flutter
    kstars
    phd2
    indi-full
    indi-3rdparty.indi-toupbase
  ];

  networking.firewall = {
    allowedTCPPorts = [ 21115 21116 21117 21118 21119 ];
    allowedUDPPorts = [ 21116 ];
  };
}
