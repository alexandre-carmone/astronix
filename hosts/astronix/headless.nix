
{ config, pkgs, ... }:
{
  services.displayManager.defaultSession = "plasmax11";
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = "alexandre";
  };
  services.xrdp = {
    enable = true;
    defaultWindowManager = "startplasma-x11";
    openFirewall = true;
  };
  services.desktopManager.plasma6.enable = true;

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  services.xserver = {
    enable = true;

    screenSection = ''
      DefaultDepth 24
      SubSection "Display"
        Depth 24
        Virtual 2560 1440
      EndSubSection
    '';
  };
}
