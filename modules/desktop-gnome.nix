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
          accent-color = "blue";
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
    adwaita-icon-theme
  ];
}
