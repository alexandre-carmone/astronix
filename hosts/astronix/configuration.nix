{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./headless.nix
    ../../modules/common.nix
  ];

  networking.hostName = "nixos";

  # Generate a fake EDID and pin it to HDMI-A-1 so the connector is
  # always reported connected at 1920x1080 from boot, whether or not a
  # real monitor is plugged in. Without this Xorg falls back to 1024x768.
  hardware.display.edid.modelines."FHD_60" =
    "173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync";
  hardware.display.outputs."HDMI-A-1".edid = "FHD_60.bin";
  hardware.display.outputs."HDMI-A-1".mode = "e";

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
