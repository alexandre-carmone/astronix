{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./displaylink.nix
    ../../modules/common.nix
  ];

  networking.hostName = "dev";

  programs.firefox.enable = true;

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

  services.printing.enable = true;
  programs.dconf.profiles.user.databases = [
    {
      lockAll = true; # prevents overriding
      settings = {
        "org/gnome/desktop/interface" = {
          accent-color = "blue";
        };
        "org/gnome/desktop/input-sources" = {
          xkb-options = [ "nocaps:escape"];
          sources = [ (lib.gvariant.mkTuple [ "xkb" "us_qwerty-fr" ]) ];
        };
      };
    }
  ];
  services.udev.packages = [
    pkgs.indi-full
    pkgs.indi-3rdparty.indi-toupbase
    pkgs.indi-3rdparty.indi-playerone
  ];


  environment.systemPackages = with pkgs; [
    gcc
    git
    gnumake
    gpclient
    teams-for-linux
    signal-desktop
    btop
    ffmpeg
    vlc
    claude-code
    ffmpeg
    fd
    
    # astro config
    rustdesk-flutter
    kstars
    phd2
    siril
    gimp
    indi-full
    indi-3rdparty.indi-toupbase
    indi-3rdparty.indi-playerone

    gnomeExtensions.blur-my-shell
    gnomeExtensions.just-perfection
    adwaita-icon-theme
    gnomeExtensions.arc-menu
  ];

    security.pki.certificateFiles = [
    ./certs/bundle.crt
  ];

environment.etc."ssl/openssl-legacy.cnf".text = ''
    openssl_conf = default_conf

    [default_conf]
    ssl_conf = ssl_sect

    [ssl_sect]
    system_default = ssl_default_sect

    [ssl_default_sect]
    Options = UnsafeLegacyRenegotiation
  '';

  environment.variables.OPENSSL_CONF = "/etc/ssl/openssl-legacy.cnf";
}
