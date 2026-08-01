{ pkgs, ... }:

# Headless Plasma desktop for the astrophoto rig: Plasma 6 on X11 with SDDM
# autologin and xrdp for remote access. A fake EDID is pinned to HDMI-A-1 so the
# connector always reports connected at 1920x1080 from boot, whether or not a
# real monitor is plugged in (without it Xorg falls back to 1024x768), and the
# matching Xorg modelines are declared so the virtual display can be resized.
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

  # Keyboard layout for the local/remote session (overrides the qwerty-fr default
  # from modules/input.nix on this headless host).
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Fake EDID pinned to HDMI-A-1 so the connector is always reported connected at
  # 1920x1080 from boot.
  hardware.display.edid.modelines."FHD_60" =
    "173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync";
  hardware.display.outputs."HDMI-A-1".edid = "FHD_60.bin";
  hardware.display.outputs."HDMI-A-1".mode = "e";

  services.xserver = {
    enable = true;

    monitorSection = ''
      HorizSync   15.0 - 200.0
      VertRefresh 15.0 - 200.0
      Modeline "1920x1080" 173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync
      Modeline "2560x1440" 241.50 2560 2608 2640 2720 1440 1443 1448 1481 +hsync -vsync
      Modeline "1680x1050" 146.25 1680 1784 1960 2240 1050 1053 1059 1089 -hsync +vsync
      Option "PreferredMode" "1920x1080"
    '';

    screenSection = ''
      DefaultDepth 24
      SubSection "Display"
        Depth 24
        Modes "1920x1080" "2560x1440" "1680x1050"
        Virtual 1920 1080
      EndSubSection
    '';
  };

  users.users.alexandre.packages = with pkgs; [
    kdePackages.kate
  ];
}
