{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/astro.nix
    ../../modules/desktop-gnome.nix
    ../../modules/docker.nix
    ./displaylink.nix
  ];

  networking.hostName = "inix";

  # Synaptics fingerprint reader (USB 06cb:00f0) — supported by the open
  # libfprint "synaptics" driver. NixOS wires pam_fprintd into PAM automatically
  # (GDM login, screen unlock, sudo). Enroll with `fprintd-enroll` after rebuild.
  services.fprintd.enable = true;

  environment.systemPackages = with pkgs; [
    gcc
    gnumake
    gpclient
    teams-for-linux
    signal-desktop
    vlc
    claude-code
    ffmpeg
  ];

  # Corporate CA bundle + OpenSSL legacy renegotiation for the corp VPN/proxy.
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
