# Printing: CUPS + declarative network printers.
#
# Imported per host (only by hosts/dev, i.e. inix), so CUPS and the driverless
# (IPP Everywhere) stack are pulled in only where a printer is actually used.
# Individual printers are declared in the host's configuration.nix via
# `services.astronix.printing.printers`.
#
# Driverless means no vendor PPD/driver package: CUPS queries the printer over
# IPP, asks it which formats it speaks (PDF/PWG-Raster/AppleRaster) and builds
# the queue from the printer's own answer. It works on most network printers
# sold since ~2015 — but see the Kyocera note below before assuming a printer
# really renders what it claims to accept.
#
# Example usage (in a host's configuration.nix):
#
#   services.astronix.printing.printers.travail = {
#     address = "10.20.30.40";
#     description = "Ricoh MP C3004 - 2e etage";
#     location = "Bureau";
#     auth = "username-password";   # popup login/mot de passe a l'impression
#     default = true;
#     options = {
#       PageSize = "A4";
#       sides = "two-sided-long-edge";
#       print-color-mode = "monochrome";
#     };
#   };
#
# Kyocera specifics (ECOSYS / TASKalfa), learned the hard way:
#
#   * Do NOT trust their IPP answer on formats. A TASKalfa 3554ci advertises
#     `application/pdf` and `image/pwg-raster` in document-format-supported and
#     even `ipp-features-supported = airprint-2.1`, yet its printer-device-id
#     reads `CMD:PCLXL,PostScript Emulation,PCL5C,PJL` — no PDF, no raster.
#     Those formats live in the firmware's AirPrint layer, not in the print
#     engine. Since document-format-default is `application/octet-stream`, the
#     engine sniffs the incoming bytes, fails to recognise PWG-Raster/PDF and
#     dumps them as text: dozens of pages of garbage. Check the CMD list of
#     printer-device-id and pick a `model` whose output language is in it —
#     `drv:///sample.drv/generic.ppd` (PostScript, colour + duplex) is the safe
#     answer for these MFPs.
#   * Plain IPP is on 631, but Kyocera's Command Center RX exposes *IPPS* on
#     port 443, not 631, on a good number of models. If `ipps://IP/ipp/print`
#     times out, set `port = 443` before concluding that TLS is unavailable.
#   * Their TLS certificate is usually self-signed. CUPS accepts it for printing
#     by default (see `services.printing.extraConf` if it ever refuses).
#   * Model-specific PPDs (trays, finisher, stapling) are not in nixpkgs for the
#     TASKalfa line: cups-kyocera only covers FS-10xx GDI models and
#     cups-kyocera-ecosys-m552x-p502x the ECOSYS M55xx/P50xx. Getting those
#     options means packaging Kyocera's official PPD by hand.
#   * If the device runs "Job Accounting", it wants a numeric account code
#     rather than a login, and that is NOT `auth-info-required`. Pass it as a
#     job option instead: `options."job-account-id" = "1234";`
#
# NOTE on `auth`: with "username-password" CUPS marks the queue
# `auth-info-required=username,password`. Jobs are held as "pending
# authentication" until credentials are supplied — the GTK/GNOME print dialog
# pops up a login prompt on the first job and the session keeps them cached.
# Nothing is ever written to the Nix store, which is why credentials must NOT be
# put in `address` as user:pass@host: /nix/store is world-readable and this repo
# is under git.
{ config, lib, pkgs, ... }:

let
  cfg = config.services.astronix.printing;

  # CUPS `auth-info-required` attribute values.
  authValues = {
    "none" = "none";
    "username-password" = "username,password";
    "domain-username-password" = "domain,username,password";
    "negotiate" = "negotiate";
  };

  printerModule = { name, ... }: {
    options = {
      address = lib.mkOption {
        type = lib.types.str;
        example = "10.20.30.40";
        description = "IP address or hostname of the printer.";
      };

      resource = lib.mkOption {
        type = lib.types.str;
        default = "/ipp/print";
        description = ''
          IPP resource path on the printer. `/ipp/print` is the IPP Everywhere
          standard and is right for virtually every modern printer. Some older
          or server-hosted queues use `/printers/<queue>` instead.
        '';
      };

      encrypted = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Use `ipps://` (IPP over TLS) rather than plain `ipp://`.

          Keep this on whenever the printer requires authentication: IPP auth is
          HTTP Basic, so over plain `ipp://` the password crosses the network in
          clear text. Turn it off only if the printer has no TLS listener.
        '';
      };

      port = lib.mkOption {
        type = lib.types.nullOr lib.types.port;
        default = null;
        description = "Override the IPP port (default 631 for both ipp and ipps).";
      };

      auth = lib.mkOption {
        type = lib.types.enum (lib.attrNames authValues);
        default = "none";
        description = ''
          How the printer authenticates jobs.

          - `none`: open queue, no credentials.
          - `username-password`: CUPS prompts for a login and password at print
            time and does not store them on disk.
          - `domain-username-password`: same, plus a Windows/AD domain field.
          - `negotiate`: Kerberos/GSSAPI, uses the session ticket, no prompt.
        '';
      };

      description = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Human-readable description shown in print dialogs.";
      };

      location = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Human-readable location (e.g. building/floor).";
      };

      model = lib.mkOption {
        type = lib.types.str;
        default = "everywhere";
        description = ''
          PPD/driver to use. `everywhere` is driverless IPP Everywhere: CUPS
          derives the queue from the printer's own IPP attributes, so the
          printer must be reachable when the queue is created.

          Override only if the printer is not driverless-capable; `lpinfo -m`
          lists what is available.
        '';
      };

      default = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Make this the system default printer.";
      };

      options = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = { PageSize = "A4"; sides = "two-sided-long-edge"; };
        description = ''
          Default job options for the queue, passed to `lpadmin -o`. Inspect the
          supported set once the queue exists with `lpoptions -p <name> -l`.
        '';
      };
    };
  };

  mkUri = p:
    let
      scheme = if p.encrypted then "ipps" else "ipp";
      portPart = lib.optionalString (p.port != null) ":${toString p.port}";
    in
    "${scheme}://${p.address}${portPart}${p.resource}";

  defaultPrinters =
    lib.attrNames (lib.filterAttrs (_: p: p.default) cfg.printers);
in
{
  options.services.astronix.printing = {
    printers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule printerModule);
      default = { };
      description = ''
        Network printers to configure declaratively, keyed by queue name.
        Queues are created on boot and re-applied on every rebuild.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = lib.length defaultPrinters <= 1;
        message =
          "services.astronix.printing: only one printer can be the default, "
          + "but these are all marked `default = true`: "
          + lib.concatStringsSep ", " defaultPrinters;
      }
    ];

    services.printing = {
      enable = true;
      # Ship the generic drivers too, so a non-driverless printer added by hand
      # through the GNOME/web UI still finds a PPD.
      drivers = with pkgs; [ gutenprint ];
      # Pick up printers shared by a CUPS server on the LAN, in addition to the
      # ones declared below.
      browsing = true;
    };

    # mDNS/DNS-SD: lets CUPS and the GNOME printer panel discover printers that
    # announce themselves on the LAN, and resolves *.local names. Printers
    # declared above are reached by IP and do not depend on this.
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
    };

    # Managing queues from the GNOME Settings > Printers panel and from
    # localhost:631 requires membership of the CUPS admin group.
    users.users.alexandre.extraGroups = [ "lpadmin" ];

    environment.systemPackages = with pkgs; [
      system-config-printer # GUI for queues/jobs, also used by GNOME
    ];

    hardware.printers = {
      ensurePrinters = lib.mapAttrsToList
        (name: p: {
          inherit name;
          inherit (p) description location model;
          deviceUri = mkUri p;
          ppdOptions = p.options // {
            "auth-info-required" = authValues.${p.auth};
          };
        })
        cfg.printers;

      ensureDefaultPrinter = lib.mkIf (defaultPrinters != [ ]) (lib.head defaultPrinters);
    };

    # `lpadmin -m everywhere` has to talk to the printer to build the queue, so
    # on a laptop the ensure-printers unit fails on every boot away from the
    # office. Retry a few times rather than giving up at once: that covers the
    # normal case of NetworkManager still bringing up Wi-Fi/VPN at boot. After
    # the burst it stays failed until the next rebuild or a manual
    # `systemctl restart ensure-printers`.
    systemd.services.ensure-printers = lib.mkIf (cfg.printers != { }) {
      startLimitIntervalSec = 600;
      startLimitBurst = 5;
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = 60;
      };
    };
  };
}
