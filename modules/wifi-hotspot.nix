# Example:
#
#   services.astronix.wifi = {
#     enable = true;
#     networks = {
#       home = { priority = 20; };
#       phone = { priority = 30; };
#     };
#     hotspot = {
#       ssid = "astronix";
#     };
#   };
#
# Then create /etc/astronix/wifi.env (root, 0600):
#   HOME_SSID=MyHomeNet
#   HOME_PSK=supersecret
#   PHONE_SSID=AlexPhone
#   PHONE_PSK=hotspotpass
#   HOTSPOT_PSK=astronix-hotspot
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
        Root-owned 0600 file holding the credentials. Each entry in
        `networks` needs `<KEY>_SSID` and `<KEY>_PSK`, where <KEY> is its name
        upper-cased. For networks = { home = {...}; phone = {...}; }:
          HOME_SSID=MyHomeNet
          HOME_PSK=supersecret
          PHONE_SSID=AlexPhone
          PHONE_PSK=hotspotpass
        The hotspot reads its passphrase from the same file, under the
        variable named by `hotspot.passphraseVar`:
          HOTSPOT_PSK=astronix-hotspot
        Values never enter the nix store.
      '';
    };

    networks = lib.mkOption {
      default = { home = { priority = 20; }; };
      description = ''
        Wifi networks to try, by name. The name, upper-cased, is also the
        env-var prefix in `credentialsFile`. When several are in range, the
        higher priority wins.
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
              Wifi security:
              - "wpa-psk": WPA/WPA2 Personal, most home networks.
              - "sae":     WPA3 Personal, for pure-WPA3 APs.
              - "none":    open network, PSK env var ignored.
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

      passphraseVar = lib.mkOption {
        type = lib.types.str;
        default = "HOTSPOT_PSK";
        description = ''
          Variable in `credentialsFile` holding the hotspot passphrase, 8
          characters minimum. It never enters the nix store. If the variable is
          missing the key ends up empty and the AP refuses every client.
        '';
      };

      band = lib.mkOption {
        type = lib.types.enum [ "bg" "a" ];
        default = "bg";
        description = "Band: bg (2.4 GHz, best range) or a (5 GHz).";
      };

      security = lib.mkOption {
        type = lib.types.enum [ "wpa-psk" "sae" "none" ];
        default = "wpa-psk";
        description = ''
          Hotspot security:
          - "wpa-psk": WPA2 Personal, the widest client support.
          - "sae":     WPA3 Personal, older clients can't join.
          - "none":    open AP, passphrase ignored.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.networkmanager.enable = true;
    networking.networkmanager.wifi.powersave = false;

    # Lets hotspot clients get a DHCP lease (UDP 67) and resolve DNS (53)
    # from the dnsmasq NetworkManager runs for the shared profile. Without
    # them the AP is visible, clients associate, and no one gets an IP.
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
            psk = "$" + cfg.hotspot.passphraseVar;
          };
        };
      };
    };
  };
}
