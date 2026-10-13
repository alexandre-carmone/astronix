{ pkgs, ... }:

# Headless Plasma desktop for the rig.
# Plasma 6 on X11, SDDM autologin, and xrdp for remote access.
#
# A fake EDID makes HDMI-A-1 look connected at 1920x1080 from boot,
# with or without a monitor. Without it, Xorg falls back to 1024x768.
# The modelines below let you resize the display.
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

  # Keyboard layout for local and remote sessions.
  # Overrides the qwerty-fr default from modules/input.nix.
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # The fake EDID, and the modes the virtual display can take.
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

  # Dark only. At each login:
  #   - apply the Breeze Dark color scheme
  #   - turn off Plasma's automatic light/dark switching
  # Plasma's own tool also recolours GTK apps (PHD2). It also sets the portal
  # color scheme that Ghostty follows. It does nothing once the scheme is set.
  # Only the color scheme, not the Breeze Dark global theme. The global theme
  # would also reset the wallpaper and cursor at every login.
  systemd.user.services.plasma-dark = {
    description = "Apply the Breeze Dark color scheme";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    # After kded. Its gtkconfig module recolours GTK on the change.
    after = [ "graphical-session.target" "plasma-kded6.service" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals \
        --group KDE --key AutomaticLookAndFeel false
      ${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-colorscheme BreezeDark
    '';
  };
}
