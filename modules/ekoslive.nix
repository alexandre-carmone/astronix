{ config, lib, pkgs, ... }:

# Connects KStars to an Ekos Live server every time it starts, with no trip
# to the Ekos Live dialog.
#
# KStars' own "Auto start" can't do it here. It keeps the password in the
# keychain and connects only if it can read it back at startup, and KWallet
# is off (./keyring.nix). So `kstars` is wrapped instead: before launch the
# wrapper writes the server into kstarsrc, then a helper waits for Ekos to
# come up on D-Bus and logs in with the credentials below.
#
# The wrapper replaces pkgs.kstars through an overlay, so the desktop
# launcher and junos-web's Launch button both go through it.
#
# Example:
#
#   services.astronix.ekosLive = {
#     enable = true;
#     server = "http://localhost:8080";
#     username = "alexandre";
#     password = "junos";
#   };
let
  cfg = config.services.astronix.ekosLive;
  inherit (lib) escapeShellArg;

  busctl = "${config.systemd.package}/bin/busctl";
  ekos = "${busctl} --user call -- org.kde.kstars /KStars/Ekos org.kde.kstars.Ekos";

  # Ekos registers /KStars/Ekos only once KStars has loaded its catalogs,
  # which takes a while. $1 is the KStars pid: give up if it exits first.
  login = pkgs.writeShellScript "ekoslive-login" ''
    until ${ekos} setEkosLiveUser ss \
        ${escapeShellArg cfg.username} ${escapeShellArg cfg.password} 2>/dev/null; do
      kill -0 "$1" 2>/dev/null || exit 0
      sleep 2
    done
    ${ekos} setEkosLiveConnected b true
  '';

  prelaunch = pkgs.writeShellScript "kstars-ekoslive" ''
    ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kstarsrc \
      --group EkosLive --key EkosLiveOfflineServer ${escapeShellArg cfg.server}

    # A second kstars only raises the running one, which is logged in already.
    # Logging in again would make it re-authenticate and drop the connection.
    if ! ${busctl} --user status org.kde.kstars >/dev/null 2>&1; then
      ${login} "$1" &
    fi
  '';
in
{
  options.services.astronix.ekosLive = {
    enable = lib.mkEnableOption "logging KStars into an Ekos Live server at launch";

    server = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:8080";
      example = "http://192.168.1.10:8080";
      description = ''
        Ekos Live server KStars connects to, written as its "Offline" server.
        junos-web listens for KStars on its httpAddr.
      '';
    };

    username = lib.mkOption {
      type = lib.types.str;
      description = "Ekos Live username. KStars won't connect with an empty one.";
    };

    password = lib.mkOption {
      type = lib.types.str;
      description = ''
        Ekos Live password. It lands in the world-readable nix store, which is
        fine for junos-web: it accepts any credentials. KStars also sends
        them to its "Online" server, ekoslive.com, so don't reuse a real one.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [
      (final: prev: {
        kstars = prev.symlinkJoin {
          name = "kstars-ekoslive";
          paths = [ prev.kstars ];
          nativeBuildInputs = [ prev.makeWrapper ];
          # The wrapper execs KStars, so its $$ is the KStars pid.
          postBuild = ''
            wrapProgram $out/bin/kstars --run '${prelaunch} $$'
          '';
        };
      })
    ];
  };
}
