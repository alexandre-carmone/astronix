# Declarative Syncthing sync (e.g. laptop <-> NAS).
#
# The Nix config is the single source of truth: devices and folders declared
# here are pushed to Syncthing and GUI-side changes are overridden. Just drop in
# device IDs and folder rules, rebuild, and it syncs automatically.
#
# Per folder you control BOTH the sync direction (`type`) and whether the data
# is encrypted at rest on a remote (per-device `encryptionPasswordFiles`).
#
# Example usage (in a host's configuration.nix):
#
#   services.astronix.syncthing = {
#     enable = true;
#     devices.nas = "AAAAAAA-BBBBBBB-CCCCCCC-DDDDDDD-EEEEEEE-FFFFFFF-GGGGGGG-HHHHHHH";
#
#     # Pure two-way sync, plaintext both ends:
#     folders.documents = {
#       path = "/home/alexandre/Sync";
#       devices = [ "nas" ];
#       type = "sendreceive";
#     };
#
#     # Upload-only backup, encrypted at rest on the NAS (NAS can't read it):
#     folders.backup = {
#       path = "/home/alexandre/Backup";
#       devices = [ "nas" ];
#       type = "sendonly";
#       encryptionPasswordFiles.nas = "/etc/astronix/syncthing/nas.key";
#     };
#   };
#
# One-time pairing: after the first rebuild, this host generates its own device
# ID (from a TLS cert). Add that ID on the NAS and share the same folder back;
# put the NAS's device ID in `devices.nas`. Get this host's ID with:
#   syncthing --device-id --home=/home/alexandre/.config/syncthing
{ config, lib, ... }:

let
  cfg = config.services.astronix.syncthing;
in
{
  options.services.astronix.syncthing = {
    enable = lib.mkEnableOption "declarative Syncthing folder sync";

    user = lib.mkOption {
      type = lib.types.str;
      default = "alexandre";
      description = "User that owns the Syncthing process and synced folders.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/alexandre";
      description = ''
        Base directory for Syncthing state and config. Relative folder paths
        resolve under it; the config lives in `<dataDir>/.config/syncthing`.
      '';
    };

    devices = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = { nas = "AAAAAAA-BBBBBBB-CCCCCCC-DDDDDDD-EEEEEEE-FFFFFFF-GGGGGGG-HHHHHHH"; };
      description = ''
        Remote devices to sync with, as friendly name -> Syncthing device ID.
        Folder `devices` lists reference these names. Device IDs are public and
        safe to commit.
      '';
    };

    folders = lib.mkOption {
      default = { };
      description = ''
        Folders to sync, keyed by Syncthing folder id/label. Each folder's
        `devices` list references keys of `devices`.
      '';
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          path = lib.mkOption {
            type = lib.types.str;
            description = "Local filesystem path of the synced folder.";
          };

          devices = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Names (keys of `devices`) to share this folder with.";
          };

          type = lib.mkOption {
            type = lib.types.enum [
              "sendreceive"
              "sendonly"
              "receiveonly"
              "receiveencrypted"
            ];
            default = "sendreceive";
            description = ''
              Sync direction / role for this folder on THIS host:
              - "sendreceive":      pure two-way sync (push local + pull remote).
              - "sendonly":         upload only (push local changes, ignore remote).
              - "receiveonly":      download only (accept remote changes, never push local).
              - "receiveencrypted": store an encrypted-at-rest copy for an untrusted
                                    peer (this host can't read the data; the trusted
                                    peer supplies the password). Use this when THIS
                                    host is the dumb storage target.
              See https://docs.syncthing.net/users/config.html#config-option-folder.type
            '';
          };

          encryptionPasswordFiles = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = { };
            example = { nas = "/etc/astronix/syncthing/nas.key"; };
            description = ''
              Optional per-remote-device encryption. Maps a device name (a key of
              `devices`) to a path holding the encryption password. When set, that
              remote stores this folder ENCRYPTED at rest and cannot read the
              contents (untrusted device); the remote must set the folder type to
              "receiveencrypted" with the same password. The file is read at
              service activation and never enters the nix store, so keep it as a
              root-owned 0600 file under e.g. /etc/astronix/syncthing/.
            '';
          };
        };
      });
    };
  };

  config = lib.mkIf cfg.enable {
    services.syncthing = {
      enable = true;
      user = cfg.user;
      group = "users";
      dataDir = cfg.dataDir;
      configDir = "${cfg.dataDir}/.config/syncthing";
      openDefaultPorts = true; # TCP/UDP 22000 sync + UDP 21027 local discovery
      overrideDevices = true; # Nix config is authoritative (fully declarative)
      overrideFolders = true;
      guiAddress = "127.0.0.1:8384"; # localhost only
      settings = {
        devices = lib.mapAttrs (_: id: { inherit id; }) cfg.devices;
        folders = lib.mapAttrs (_: f: {
          inherit (f) path type;
          # A device is a plain name unless it has an encryption password, in
          # which case it becomes { name; encryptionPasswordFile; }.
          devices = map (
            dev:
            if f.encryptionPasswordFiles ? ${dev} then
              {
                name = dev;
                encryptionPasswordFile = f.encryptionPasswordFiles.${dev};
              }
            else
              dev
          ) f.devices;
        }) cfg.folders;
      };
    };
  };
}
