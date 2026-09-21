{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/astro.nix
    ../../modules/desktop-gnome.nix
    ../../modules/docker.nix
    ../../modules/wine.nix
    ../../modules/autostakkert.nix
    ../../modules/graxpert.nix
    ../../modules/syncthing.nix
    ../../modules/printing.nix
    ./displaylink.nix
  ];

  networking.hostName = "inix";

  # Syncthing sync with the NAS. Paste the NAS device ID below; get this
  # host's own with `syncthing --device-id --home=~/.config/syncthing` and add
  # it on the NAS side.
  #services.astronix.syncthing = {
  #  enable = true;
  #  devices.nas = "PASTE-NAS-DEVICE-ID-HERE";
  #  folders.documents = {
  #    path = "/home/alexandre/Sync";
  #    devices = [ "nas" ];
  #    type = "sendreceive"; # sendreceive | sendonly | receiveonly | receiveencrypted
      # To store this folder encrypted on the NAS:
      #   encryptionPasswordFiles.nas = "/etc/astronix/syncthing/nas.key";
  #  };
  #};

  # SCSI generic driver, for the /dev/sgN nodes. MakeMKV drives the optical
  # drive through /dev/sg*, not /dev/sr0. Needed to read UHD Blu-rays.
  boot.kernelModules = [ "sg" ];

  # darkman switches the theme by rebuilding, which needs root (see
  # modules/darkman.nix). These two exact commands run without a password.
  # Nothing else does.
  security.sudo.extraRules = [
    {
      users = [ "alexandre" ];
      commands = [
        { command = "/run/current-system/sw/bin/nixos-rebuild switch --flake /home/alexandre/astronix#dev-dark"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/nixos-rebuild switch --flake /home/alexandre/astronix#dev"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  # Synaptics fingerprint reader (USB 06cb:00f0), driven by libfprint. NixOS
  # wires it into GDM login, screen unlock and sudo. Enroll with
  # `fprintd-enroll` after the rebuild.
  services.fprintd.enable = true;

  environment.systemPackages = with pkgs; [
    gcc
    gnumake
    gpclient
    teams-for-linux
    signal-desktop
    vlc
    #makemkv # rips UHD Blu-rays to mkv (libaacs/VLC can't)
    claude-code
    ffmpeg
    freecad
    orca-slicer
  ];

  # Corporate CA bundle and legacy renegotiation, for the corp VPN/proxy.
  security.pki.certificateFiles = [
    ./certs/bundle.crt
  ];
  environment.sessionVariables.SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
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
