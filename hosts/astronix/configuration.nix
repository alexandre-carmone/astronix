{ config, lib, pkgs, inputs, ... }:

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
      # Passphrase is HOTSPOT_PSK in /etc/astronix/wifi.env, not here.
      security = "wpa-psk";
    };
  };

  # The astrophoto data disk (internal NVMe, ext4, label "datas"). Declared
  # here so it mounts at boot. Plasma used to mount it on demand through
  # udisks2, which asked for a polkit password every boot, and junos-web
  # crash-looped until someone typed it.
  #
  # Keep the mount point as it is. capturesDir below and the KStars/Ekos
  # sequences on the disk all point at /run/media/alexandre/datas.
  #
  # nosuid/nodev are what udisks2 used. nofail means a dead disk breaks
  # junos-web, not the boot.
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
    #tls.cert = "/run/secrets/junos-cert.pem";
    #tls.key  = "/run/secrets/junos-key.pem";
  };

  # nofail means nothing waits for the disk, so declare the dependency
  # junos-web really has. Without capturesDir it retries every 5s forever.
  systemd.services.junos-web.unitConfig.RequiresMountsFor =
    "/run/media/alexandre/datas";

  # Run as alexandre. capturesDir sits on the astrophoto disk, owned by him
  # behind a 0700 mount point, so the default DynamicUser cannot traverse it:
  # every /api/files/* request answers 500 and the Files tab stays empty. Being
  # the owner also fixes the writes (thumbnail cache, rename, delete).
  # ProtectHome=tmpfs still hides the rest of his home.
  systemd.services.junos-web.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User  = "alexandre";
    Group = "users";
  };

  environment.systemPackages = with pkgs; [
    rustup
    ghostty
  ];

  nix.settings = {
    max-jobs = 1;        # un seul build à la fois
    cores = 0;           # tous les cores pour ce build
  };

  networking.firewall = {
    allowedTCPPorts = [ 21115 21116 21117 21118 21119 ];
    allowedUDPPorts = [ 21116 ];
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    IdleAction = "ignore";
  };

  # RustDesk 1.4.9 dlopens libxdo instead of linking it, and nothing in its
  # closure ships the library. Every lookup fails and RustDesk then drops all
  # keyboard and mouse injection, silently. Video and clipboard still work, so
  # the session connects and looks frozen. 1.4.5 linked libxdo directly, which
  # is why this appeared with the September nixpkgs bump.
  systemd.user.services.rustdesk = {
    description = "RustDesk";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.rustdesk-flutter}/bin/rustdesk";
      # The package's own wrapper keeps what it inherits, so this only adds
      # libxdo to the search path.
      Environment = [ "LD_LIBRARY_PATH=${pkgs.xdotool}/lib" ];
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
