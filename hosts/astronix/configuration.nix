{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./headless.nix
    ../../modules/common.nix
  ];

  networking.hostName = "astronomix";

  # Generate a fake EDID and pin it to HDMI-A-1 so the connector is
  # always reported connected at 1920x1080 from boot, whether or not a
  # real monitor is plugged in. Without this Xorg falls back to 1024x768.
  hardware.display.edid.modelines."FHD_60" =
    "173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync";
  hardware.display.outputs."HDMI-A-1".edid = "FHD_60.bin";
  hardware.display.outputs."HDMI-A-1".mode = "e";
  services.openssh = {
    enable = true;
    ports = [22];
  };
  services.xserver.xkb.options = "caps:swapescape";
  services.printing.enable = true;
  programs.firefox.enable = true;

  users.users.alexandre.packages = with pkgs; [
    kdePackages.kate
  ];
  users.users.alexandre = {
  isNormalUser = true;
  extraGroups = [ "wheel" "dialout" ];  

  };
  services.udev.packages = [
    pkgs.indi-full
    pkgs.indi-3rdparty.indi-toupbase
  ];
  environment.systemPackages = with pkgs; [
    inputs.ekos-web-rust.packages.x86_64-linux.rekosServer
    cargo
    rustup
    ghostty
    rustdesk-flutter
    kstars
    phd2
    siril
    gimp
    indi-full
    indi-3rdparty.indi-toupbase
  ];

  networking.firewall = {
    allowedTCPPorts = [ 21115 21116 21117 21118 21119 ];
    allowedUDPPorts = [ 21116 ];
  };
}
