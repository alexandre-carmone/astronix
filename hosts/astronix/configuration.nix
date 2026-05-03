{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./headless.nix
    ../../modules/common.nix
    ../../modules/wifi-hotspot.nix
  ];

  networking.hostName = "astronomix";

  # Generate a fake EDID and pin it to HDMI-A-1 so the connector is
  # always reported connected at 1920x1080 from boot, whether or not a
  # real monitor is plugged in. Without this Xorg falls back to 1024x768.
  hardware.display.edid.modelines."FHD_60" =
    "173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync";
  hardware.display.outputs."HDMI-A-1".edid = "FHD_60.bin";
  hardware.display.outputs."HDMI-A-1".mode = "e";
  services.openssh = {
    enable = true;
    ports = [22];
  };

  services.astronix.wifi = {
    enable = true;
    networks = {
      home = {
        priority = 20;
        security= "sae";
      };
    };
    hotspot = {
      ssid = "astronix";
      passphrase = "astronix-hotspot";
      security = "wpa-psk";
    };
  };

  #services.xserver.xkb.options = "caps:swapescape";
  services.printing.enable = true;
  programs.firefox.enable = true;

  users.users.alexandre.packages = with pkgs; [
    kdePackages.kate
  ];
  users.users.alexandre = {
  isNormalUser = true;
  extraGroups = [ "wheel" "dialout" ];  

  };
  services.udev.packages = [
    pkgs.indi-full
    pkgs.indi-3rdparty.indi-toupbase
  ];

  services.rekos-web = {
    enable = true;
    openFirewall = true;

    capturesDir = "/home/alexandre/Pictures/astro";

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
    cargo
    rustup
    ghostty
    rustdesk-flutter
    kstars
    phd2
    siril
    gimp
    indi-full
    indi-3rdparty.indi-toupbase
  ];

  networking.firewall = {
    allowedTCPPorts = [ 21115 21116 21117 21118 21119 ];
    allowedUDPPorts = [ 21116 ];
  };


  systemd.services.rustdesk-flutter.enable = true;

}
