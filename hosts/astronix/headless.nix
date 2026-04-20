
{ config, pkgs, ... }:
{
  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.

  # Enable the KDE Plasma Desktop Environment.
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
    defaultWindowManager = "startplasma-x11";  # X11 session for xrdp
    openFirewall = true;                       # opens TCP 3389
  };
 services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };


services.xserver = {
    enable = true;
    videoDrivers = [ "dummy" ];

    monitorSection = ''
      HorizSync   15.0 - 200.0
      VertRefresh 15.0 - 200.0
      Modeline "1920x1080" 173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync
      Modeline "2560x1440" 241.50 2560 2608 2640 2720 1440 1443 1448 1481 +hsync -vsync
      Modeline "1680x1050" 146.25 1680 1784 1960 2240 1050 1053 1059 1089 -hsync +vsync
      Option "PreferredMode" "1920x1080"
    '';

    deviceSection = ''
      VideoRam 256000
    '';

    screenSection = ''
      DefaultDepth 24
      SubSection "Display"
        Depth 24
        Modes "1920x1080" "2560x1440" "1680x1050"
        Virtual 2560 1440
      EndSubSection
    '';
  };  # List packages installed in system profile. To search, run:
  # $ nix search wget
systemd.services.headless-resolution = {
  description = "Force 1920x1080 on DUMMY0";
  after = [ "display-manager.service" ];
  wantedBy = [ "graphical.target" ];
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    # SDDM tourne sur :0 avec son propre xauth
    Environment = [
      "DISPLAY=:0"
      "XAUTHORITY=/run/sddm/xauth"  # ajustez si nécessaire
    ];
    ExecStart = pkgs.writeShellScript "force-resolution" ''
      # Attend que Xorg soit prêt
      for i in $(seq 1 30); do
        ${pkgs.xorg.xrandr}/bin/xrandr >/dev/null 2>&1 && break
        sleep 1
      done
      XAUTH=$(ls /run/sddm/xauth_* 2>/dev/null | head -1)
      export XAUTHORITY="$XAUTH"
      ${pkgs.xorg.xrandr}/bin/xrandr --newmode "1920x1080_60" 173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync || true
      ${pkgs.xorg.xrandr}/bin/xrandr --addmode DUMMY0 "1920x1080_60" || true
      ${pkgs.xorg.xrandr}/bin/xrandr --output DUMMY0 --mode "1920x1080_60" || true
    '';
  };
};

}
