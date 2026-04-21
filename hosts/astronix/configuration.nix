{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./headless.nix
    ../../modules/common.nix
  ];

  networking.hostName = "nixos";

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
