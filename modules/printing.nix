# Printing : CUPS et l'imprimante du bureau.
# Importe seulement par hosts/dev, le seul hote qui en a une.
# Voir https://wiki.nixos.org/wiki/Printing
#
# Kyocera TASKalfa 3554ci, sondee avec ipptool le 2026-09-17 :
#   * port 631 ferme, 443 ouvert -> IPPS sur 443
#   * pas d'auth IPP
#   * elle ne lit ni PDF ni PWG-Raster, malgre sa reponse IPP
#     (couche AirPrint du firmware)
#
# D'ou le PPD PostScript generique. `model = "everywhere"` imprimerait du
# charabia. generic.ppd gere la couleur et le recto-verso.
# On perd les options du modele (bacs, finisher, agrafage). Il faudrait le
# PPD Kyocera officiel, absent de nixpkgs.
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
          # Noms d'options PPD, pas les mots-cles IPP `sides`/`media`.
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

  # lpadmin doit joindre l'imprimante. Hors du bureau, l'unite echoue a
  # chaque boot. On reessaie quelques fois, le temps que le Wi-Fi ou le VPN
  # monte.
  systemd.services.ensure-printers = {
    startLimitIntervalSec = 600;
    startLimitBurst = 5;
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 60;
    };
  };
}
