{ lib, pkgs, ... }:

# GNOME desktop for the dev workstation: GDM + a trimmed-down GNOME (only the
# core apps we actually use), blue accent, qwerty-fr keyboard, and a few shell
# extensions.
{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # To disable installing GNOME's suite of applications
  # and only be left with GNOME shell.
  services.gnome.core-apps.enable = true;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;
  # Disable GNOME core apps we don't use, keeping only:
  # Files (nautilus), Disk Usage Analyzer (baobab), Settings (gnome-control-center),
  # and Disks (gnome-disk-utility, enabled separately via programs.gnome-disks).
  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    gnome-user-docs
    decibels
    epiphany
    gnome-text-editor
    gnome-calculator
    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-console
    gnome-contacts
    gnome-font-viewer
    gnome-logs
    gnome-maps
    gnome-music
    gnome-system-monitor
    gnome-tecla
    gnome-weather
    loupe
    papers
    gnome-connections
    showtime
    simple-scan
    snapshot
    yelp
    seahorse
  ];

  programs.dconf.profiles.user.databases = [
    {
      lockAll = true; # prevents overriding
      settings = {
        "org/gnome/desktop/interface" = {
          # GNOME's accent enum has no "mauve"; "purple" is the closest match to
          # the Catppuccin mauve accent set in home.nix.
          accent-color = "purple";
          color-scheme = "prefer-dark";
        };
        # Wallpaper. Locked by lockAll, so it's managed here rather than via the
        # GUI. Point these at a real Siril/ImPPG export and rebuild.
        "org/gnome/desktop/background" = {
          picture-uri = "file:///home/alexandre/Pictures/wallpapers/master_noth_american.png"; # PLACEHOLDER
          picture-uri-dark = "file:///home/alexandre/Pictures/wallpapers/master_noth_american.png"; # PLACEHOLDER
          picture-options = "zoom";
        };
        "org/gnome/desktop/screensaver" = {
          picture-uri = "file:///home/alexandre/Pictures/wallpapers/master_noth_american.png"; # PLACEHOLDER
        };
        "org/gnome/shell/extensions/tilingshell" = {
          inner-gaps = lib.gvariant.mkUint32 8;
          outer-gaps = lib.gvariant.mkUint32 8;
        };
        "org/gnome/desktop/input-sources" = {
          xkb-options = [ "nocaps:escape" ];
          sources = [ (lib.gvariant.mkTuple [ "xkb" "us_qwerty-fr" ]) ];
        };
        "org/gnome/shell" = {
          disable-user-extensions = false;
          enabled-extensions = [
            "tilingshell@ferrarodomenico.com"
            "blur-my-shell@aunetx"
            "just-perfection-desktop@just-perfection"
            "arcmenu@arcmenu.com"
            "rounded-window-corners@fxgn"
            "Vitals@CoreCoding.com"
            "space-bar@luchrioh"
          ];
        };
      };
    }
  ];

  environment.systemPackages = with pkgs; [
    gnomeExtensions.tiling-shell
    gnomeExtensions.blur-my-shell
    gnomeExtensions.just-perfection
    gnomeExtensions.arc-menu
    gnomeExtensions.rounded-window-corners-reborn
    gnomeExtensions.vitals
    gnomeExtensions.space-bar
    adwaita-icon-theme
  ];
}
