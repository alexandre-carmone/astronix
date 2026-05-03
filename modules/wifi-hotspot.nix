# Example usage:
#
#   services.astronix.wifi = {
#     enable = true;
#     networks = {
#       home = { priority = 20; };
#       phone = { priority = 30; };
#     };
#     hotspot = {
#       ssid = "astronix";
#       passphrase = "astronix-hotspot";
#     };
#   };
#
# Then create /etc/astronix/wifi.env (root, 0600):
#   HOME_SSID=MyHomeNet
#   HOME_PSK=supersecret
#   PHONE_SSID=AlexPhone
#   PHONE_PSK=hotspotpass
{ config, lib, pkgs, ... }:

let
  cfg = config.services.astronix.wifi;
in
{
  options.services.astronix.wifi = {
    enable = lib.mkEnableOption "preconfigured wifi with auto hotspot fallback";

    credentialsFile = lib.mkOption {
      type = lib.types.path;
      default = "/etc/astronix/wifi.env";
      description = ''
        Path to a root-owned, mode 0600 file defining the credentials for all
        declared networks. For each entry in `networks`, this file must export
        `<KEY>_SSID` and `<KEY>_PSK` where <KEY> is the upper-cased network
        name. Example for networks = { home = {...}; phone = {...}; }:
          HOME_SSID=MyHomeNet
          HOME_PSK=supersecret
          PHONE_SSID=AlexPhone
          PHONE_PSK=hotspotpass
        Values never enter the nix store.
      '';
    };

    networks = lib.mkOption {
      default = { home = { priority = 20; }; };
      description = ''
        Set of preconfigured wifi networks to try, by attribute name. The name
        is also used to derive the env-var prefix in `credentialsFile`
        (upper-cased). Higher priority is preferred when multiple are in range.
      '';
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          priority = lib.mkOption {
            type = lib.types.int;
            default = 10;
            description = "NetworkManager autoconnect-priority (higher = preferred).";
          };
          hidden = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Whether this is a hidden SSID.";
          };
          security = lib.mkOption {
            type = lib.types.enum [ "wpa-psk" "sae" "none" ];
            default = "wpa-psk";
            description = ''
              Wifi security protocol:
              - "wpa-psk": WPA/WPA2 Personal (most home networks).
              - "sae":     WPA3 Personal. Use for pure-WPA3 APs.
              - "none":    open network, no passphrase (PSK env var ignored).
            '';
          };
        };
      });
    };

    hotspot = {
      ssid = lib.mkOption {
        type = lib.types.str;
        default = "astronix";
        description = "SSID broadcast by the fallback hotspot.";
      };

      passphrase = lib.mkOption {
        type = lib.types.str;
        default = "astronix-hotspot";
        description = "WPA2 passphrase for the fallback hotspot (min 8 chars).";
      };

      band = lib.mkOption {
        type = lib.types.enum [ "bg" "a" ];
        default = "bg";
        description = "Wifi band: bg (2.4 GHz, best range/compat) or a (5 GHz).";
      };

      security = lib.mkOption {
        type = lib.types.enum [ "wpa-psk" "sae" "none" ];
        default = "wpa-psk";
        description = ''
          Hotspot security protocol:
          - "wpa-psk": WPA2 Personal (broadest client compatibility).
          - "sae":     WPA3 Personal. Some older clients can't join.
          - "none":    open AP, no passphrase (passphrase ignored).
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;
    networking.networkmanager.wifi.powersave = false;

    # Allow hotspot clients to obtain a DHCP lease (UDP 67) and resolve
    # DNS (53) via the dnsmasq instance NetworkManager runs for the
    # `ipv4.method = "shared"` profile. Without these the AP is visible
    # but clients associate and never get an IP.
    networking.firewall.allowedUDPPorts = [ 53 67 ];
    networking.firewall.allowedTCPPorts = [ 53 ];

    networking.networkmanager.ensureProfiles = {
      environmentFiles = [ cfg.credentialsFile ];

      profiles = (lib.mapAttrs' (name: net:
        let key = lib.toUpper name; in
        lib.nameValuePair "wifi-${name}" ({
          connection = {
            id = "wifi-${name}";
            type = "wifi";
            autoconnect = true;
            "autoconnect-priority" = net.priority;
          };
          wifi = {
            mode = "infrastructure";
            ssid = "$" + key + "_SSID";
          } // lib.optionalAttrs net.hidden { hidden = true; };
          ipv4.method = "auto";
          ipv6.method = "auto";
        } // lib.optionalAttrs (net.security != "none") {
          wifi-security = {
            "key-mgmt" = net.security;
            psk = "$" + key + "_PSK";
          };
        })
      ) cfg.networks) // {
        astronix-hotspot = {
          connection = {
            id = "astronix-hotspot";
            type = "wifi";
            autoconnect = true;
            "autoconnect-priority" = -10;
            "autoconnect-retries" = 0;
          };
          wifi = {
            mode = "ap";
            band = cfg.hotspot.band;
            ssid = cfg.hotspot.ssid;
          };
          ipv4.method = "shared";
          ipv6.method = "ignore";
        } // lib.optionalAttrs (cfg.hotspot.security != "none") {
          wifi-security = {
            "key-mgmt" = cfg.hotspot.security;
            psk = cfg.hotspot.passphrase;
          };
        };
      };
    };
  };
}
