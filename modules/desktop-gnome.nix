{ lib, pkgs, theme ? "light", ... }:

# GNOME for the dev workstation: GDM, a trimmed-down GNOME, purple accent,
# qwerty-fr keyboard and a few shell extensions. The light/dark bits come from
# the shared theme preset, so they follow the `theme` flake arg.
let
  preset = import ./theme.nix theme;
in
{
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Keep the core apps; drop the developer tools and the games.
  services.gnome.core-apps.enable = true;
  services.gnome.core-developer-tools.enable = false;
  services.gnome.games.enable = false;
  # Drop the core apps we don't use. What's left: Files, Disk Usage Analyzer,
  # Settings, and Disks (enabled separately via programs.gnome-disks).
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
      lockAll = true; # the GUI can't override these
      settings = {
        "org/gnome/desktop/interface" = {
          # GNOME has no "mauve" accent; "purple" is the closest to the
          # Catppuccin one set in home.nix.
          accent-color = "purple";
          color-scheme = preset.colorScheme;
        };
        # Wallpaper. lockAll means the GUI can't change it, so set it here.
        "org/gnome/desktop/background" = {
          picture-uri = preset.wallpaperLight;
          picture-uri-dark = preset.wallpaperDark;
          picture-options = "zoom";
        };
        "org/gnome/desktop/screensaver" = {
          picture-uri = if theme == "dark" then preset.wallpaperDark else preset.wallpaperLight;
        };
        "org/gnome/shell/extensions/tilingshell" = {
          inner-gaps = lib.gvariant.mkUint32 8;
          outer-gaps = lib.gvariant.mkUint32 8;
        };
        # Under the light scheme, blur-my-shell turns the top-bar text dark
        # whenever a light window is maximized behind the panel. Keep it light
        # so Vitals stays readable.
        "org/gnome/shell/extensions/blur-my-shell/panel" = {
          force-light-text = preset.forceLightText;
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
