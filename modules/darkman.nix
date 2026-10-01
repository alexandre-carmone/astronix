{ host, ... }:

# Switches a GNOME host between light and dark at sunrise and sunset. The
# Catppuccin TUI themes are baked into the home-manager generation as
# read-only store symlinks, so switching means rebuilding into the sibling
# output (`#<host>` or `#<host>-dark`), not editing files at runtime. `host`
# is that flake attribute, passed by mkGnomeHost in flake.nix.
#
# The rebuild needs root, so this also grants a NOPASSWD sudo rule for these
# two exact commands. Nothing else runs without a password. Ghostty follows
# the color-scheme on its own (see home.nix), so the terminal recolours
# without waiting for the rebuild.
let
  rebuild = target:
    "/run/current-system/sw/bin/nixos-rebuild switch --flake /home/alexandre/astronix#${target}";
  dark = rebuild "${host}-dark";
  light = rebuild host;
in
{
  security.sudo.extraRules = [
    {
      users = [ "alexandre" ];
      commands = [
        { command = dark; options = [ "NOPASSWD" ]; }
        { command = light; options = [ "NOPASSWD" ]; }
      ];
    }
  ];

  home-manager.users.alexandre.services.darkman = {
    enable = true;
    settings = {
      # Sunrise and sunset come from these coordinates (Paris). Fixed coords
      # keep the geoclue daemon out.
      lat = 48.85;
      lng = 2.35;
      usegeoclue = false;
    };
    darkModeScripts.rebuild = ''
      /run/wrappers/bin/sudo ${dark}
    '';
    lightModeScripts.rebuild = ''
      /run/wrappers/bin/sudo ${light}
    '';
  };
}
