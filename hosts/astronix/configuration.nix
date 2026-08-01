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

  services.junos-web = {
    enable = true;
    openFirewall = true;

    capturesDir = "/run/media/alexandre/datas/astrophoto";
    dsoTileDir = "/run/media/alexandre/datas/dso";
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

  systemd.user.services.rustdesk = {
    description = "RustDesk";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.rustdesk-flutter}/bin/rustdesk";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
