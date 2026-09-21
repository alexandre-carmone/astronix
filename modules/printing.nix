# Printing: CUPS + the office printer, declared the upstream way
# (https://wiki.nixos.org/wiki/Printing). Imported only by hosts/dev (inix),
# the only host with a printer.
#
# Kyocera TASKalfa 3554ci, d'apres une sonde ipptool du 2026-09-17 :
#   * port 631 ferme, 443 ouvert -> IPPS sur 443 (cas Kyocera classique)
#   * aucune auth IPP exigee (Validate-Job repond successful-ok sans creds)
#   * printer-device-id CMD:PCLXL,PostScript Emulation,PCL5C,PJL : la machine
#     ne lit NI PDF NI PWG-Raster, bien que sa reponse IPP les annonce (couche
#     AirPrint du firmware). D'ou le PPD PostScript generique plutot que
#     `model = "everywhere"`, qui ferait sortir des dizaines de pages de
#     charabia. generic.ppd gere la couleur et le duplex ; ce qu'on perd, ce
#     sont les options du modele (bacs, finisher, agrafage), qui demanderaient
#     d'empaqueter le PPD Kyocera officiel, absent de nixpkgs.
{ pkgs, ... }:

{
  services.printing = {
    enable = true;
    drivers = with pkgs; [ gutenprint ];
    browsing = true; # imprimantes partagees par un serveur CUPS du LAN
  };

  # mDNS/DNS-SD : decouverte des imprimantes et resolution des noms *.local.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "travail";
        description = "Kyocera TASKalfa 3554ci";
        location = "Bureau";
        deviceUri = "ipps://10.0.28.200:443/ipp/print";
        model = "drv:///sample.drv/generic.ppd"; # Generic PostScript Printer
        ppdOptions = {
          # Noms d'options PPD (et non les mots-cles IPP `sides`/`media`).
          PageSize = "A4";
          Duplex = "DuplexNoTumble"; # recto-verso bord long
        };
      }
    ];
    ensureDefaultPrinter = "travail";
  };

  # Gerer les files depuis GNOME Settings > Printers ou localhost:631.
  users.users.alexandre.extraGroups = [ "lpadmin" ];
  environment.systemPackages = [ pkgs.system-config-printer ];

  # lpadmin doit joindre l'imprimante : hors du bureau l'unite echoue a chaque
  # boot. On retente quelques fois, le temps que le Wi-Fi/VPN monte.
  systemd.services.ensure-printers = {
    startLimitIntervalSec = 600;
    startLimitBurst = 5;
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 60;
    };
  };
}
