{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/astro.nix
    ../../modules/desktop-plasma.nix
    ../../modules/wifi-hotspot.nix
  ];

  networking.hostName = "astronomix";

  services.astronix.wifi = {
    enable = true;
    networks = {
      home = {
        priority = 20;
        security = "sae";
      };
    };
    hotspot = {
      ssid = "astronix";
      passphrase = "astronix-hotspot";
      security = "wpa-psk";
    };
  };

  # The astrophoto data disk (internal NVMe, ext4, label "datas"). Plasma's
  # device notifier used to mount this on demand through udisks2, which needs a
  # polkit password every single boot — and junos-web, whose capturesDir lives
  # on it, crash-loops until someone types it. Declaring it mounts it at boot
  # with no prompt.
  #
  # The mount point is deliberately left exactly where udisks2 put it rather
  # than moved somewhere tidier like /mnt: capturesDir below and the absolute
  # paths inside the KStars/Ekos sequences already on the disk all point at
  # /run/media/alexandre/datas, and moving it would silently break them. /run is
  # a tmpfs, but systemd creates the mount point itself on each boot.
  #
  # nosuid/nodev match what udisks2 was already using. ext4 carries its own
  # ownership, so the tree stays alexandre's. nofail means a dead or absent disk
  # degrades to "junos-web is broken" instead of "the rig will not boot".
  fileSystems."/run/media/alexandre/datas" = {
    device = "/dev/disk/by-uuid/27246b7d-d14b-46b1-a3e6-606ef3a1da2a";
    fsType = "ext4";
    options = [ "nosuid" "nodev" "nofail" "x-systemd.device-timeout=10s" ];
  };

  services.junos-web = {
    enable = true;
    openFirewall = true;

    capturesDir = "/run/media/alexandre/datas/astrophoto";
    dsoTileDir = "/home/alexandre/junos-data/dso";
    httpAddr  = "0.0.0.0:8080";
    httpsAddr = "0.0.0.0:8443";

    tls.subjectAltNames = [
      "DNS:localhost"
      "IP:127.0.0.1"
      "IP:0.0.0.0"   # the host's LAN IP — required for iOS Safari to accept the cert
      "DNS:astro.lan"
    ];
    # Or: bring your own cert (autoGenerate becomes irrelevant)
    tls.autoGenerate = true;
    #tls.cert = "/run/secrets/rekos-cert.pem";
    #tls.key  = "/run/secrets/rekos-key.pem";
  };

  # nofail on the data disk above means local-fs.target does not wait for it, so
  # state the dependency junos-web actually has: without capturesDir present it
  # fails to set up its mount namespace and then retries every 5s forever.
  systemd.services.junos-web.unitConfig.RequiresMountsFor =
    "/run/media/alexandre/datas";

  environment.systemPackages = with pkgs; [
    rustup
    ghostty
  ];

  nix.settings = {
    max-jobs = 1;        # nombre de builds en parallèle (1 = un seul à la fois)
    cores = 0;            # cores par build (0 = tous les cores disponibles)
  };

  networking.firewall = {
    allowedTCPPorts = [ 21115 21116 21117 21118 21119 ];
    allowedUDPPorts = [ 21116 ];
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    IdleAction = "ignore";
  };

  # RustDesk 1.4.9 stopped linking libxdo and now dlopens it at runtime instead
  # (libxdo-sys-stub tries libxdo.so.4, then .so.3, then .so). Nothing in the
  # package closure ships it, so on NixOS every one of those lookups fails and
  # RustDesk quietly disables *all* keyboard and mouse injection. The session
  # still streams video and syncs the clipboard, so it connects and looks alive
  # — but nothing you click or type reaches the desktop, which presents as a
  # frozen screen. 1.4.5 linked libxdo.so.4 directly, which is why this only
  # showed up with the September nixpkgs bump.
  systemd.user.services.rustdesk = {
    description = "RustDesk";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.rustdesk-flutter}/bin/rustdesk";
      # The package's own wrapper prepends /run/opengl-driver/lib and preserves
      # whatever it inherits, so this only adds libxdo to the search path.
      Environment = [ "LD_LIBRARY_PATH=${pkgs.xdotool}/lib" ];
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
