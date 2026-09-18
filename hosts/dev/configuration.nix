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

  # Kyocera TASKalfa 3554ci du bureau.
  #
  # Sonde du 2026-09-17 depuis le reseau du travail (ipptool) :
  #   * port 631 ferme, 443 ouvert -> IPPS sur 443, cas Kyocera classique
  #   * uri-authentication-supported = none, et Validate-Job repond
  #     successful-ok sans identifiants -> aucune auth IPP exigee
  #   * document-format-default = application/octet-stream : la machine devine
  #     le langage d'apres les octets recus
  #   * printer-device-id CMD:PCLXL,PostScript Emulation,PCL5C,PJL -> les seuls
  #     langages reellement interpretes. NI PDF NI PWG-Raster, bien que la
  #     reponse IPP annonce application/pdf et image/pwg-raster (couche
  #     AirPrint du firmware).
  #
  # D'ou le choix du PPD PostScript generique plutot que du driverless : avec
  # `everywhere` / "Generic IPP Everywhere Printer", CUPS envoie du PWG-Raster
  # ou du PDF que le moteur ne sait pas lire, et la machine le vide en texte
  # brut -- des dizaines de pages de charabia. En PostScript, CUPS convertit via
  # pdftops et la machine reconnait le flux immediatement.
  #
  # generic.ppd est ColorDevice:True et gere le duplex, donc rien n'est perdu
  # cote couleur. Ce qu'on perd, ce sont les options specifiques au modele
  # (bacs, finisher, agrafage) : il faudrait pour cela empaqueter le PPD
  # Kyocera officiel, absent de nixpkgs (cups-kyocera* ne couvre que les
  # FS-10xx et ECOSYS M55xx/P50xx).
  services.astronix.printing.printers.travail = {
    address = "10.0.28.200";
    port = 443;
    resource = "/ipp/print";
    description = "Kyocera TASKalfa 3554ci";
    location = "Bureau";
    auth = "none";
    default = true;
    model = "drv:///sample.drv/generic.ppd"; # Generic PostScript Printer
    options = {
      # Noms d'options PPD (et non les mots-cles IPP `sides`/`media`).
      PageSize = "A4";
      Duplex = "DuplexNoTumble"; # recto-verso bord long
    };
  };

  # Declarative Syncthing sync with the NAS. Fill in the NAS device ID below
  # (get this host's ID with `syncthing --device-id
  # --home=/home/alexandre/.config/syncthing` and add it on the NAS side).
  #services.astronix.syncthing = {
  #  enable = true;
  #  devices.nas = "PASTE-NAS-DEVICE-ID-HERE";
  #  folders.documents = {
  #    path = "/home/alexandre/Sync";
  #    devices = [ "nas" ];
  #    type = "sendreceive"; # sendreceive | sendonly | receiveonly | receiveencrypted
      # To store this folder encrypted-at-rest on the NAS (untrusted device):
      #   encryptionPasswordFiles.nas = "/etc/astronix/syncthing/nas.key";
  #  };
  #};

  # SCSI generic (sg) driver — creates /dev/sgN nodes. MakeMKV talks to the
  # optical drive through /dev/sg* (raw MMC/AACS commands), not /dev/sr0, so
  # reading (bus-encrypted UHD) Blu-rays needs this module loaded.
  boot.kernelModules = [ "sg" ];

  # Let darkman flip the theme unattended: allow alexandre to run exactly the
  # two theme-switch rebuilds without a password (see modules/darkman.nix).
  # nixos-rebuild runs switch-to-configuration as root — scope is these two
  # exact argv only, nothing else gets NOPASSWD.
  security.sudo.extraRules = [
    {
      users = [ "alexandre" ];
      commands = [
        { command = "/run/current-system/sw/bin/nixos-rebuild switch --flake /home/alexandre/astronix#dev-dark"; options = [ "NOPASSWD" ]; }
        { command = "/run/current-system/sw/bin/nixos-rebuild switch --flake /home/alexandre/astronix#dev"; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

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
    #makemkv # decrypt UHD/bus-encrypted Blu-rays to mkv (libaacs/VLC can't)
    claude-code
    ffmpeg
  ];

  # Corporate CA bundle + OpenSSL legacy renegotiation for the corp VPN/proxy.
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
