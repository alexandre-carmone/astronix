{ ... }:

# Home-manager service that switches the system between light and dark at
# sunrise and sunset. The Catppuccin TUI themes are baked into the
# home-manager generation as read-only store symlinks, so switching means
# rebuilding into the sibling output (`#dev` or `#dev-dark`), not editing
# files at runtime.
#
# That rebuild needs root; hosts/dev/configuration.nix carries a NOPASSWD rule
# for these two exact commands. Ghostty follows the color-scheme on its own
# (see home.nix), so the terminal recolours without waiting for the rebuild.
{
  services.darkman = {
    enable = true;
    settings = {
      # Sunrise and sunset come from these coordinates (Paris). Fixed coords
      # keep the geoclue daemon out.
      lat = 48.85;
      lng = 2.35;
      usegeoclue = false;
    };
    darkModeScripts.rebuild = ''
      /run/wrappers/bin/sudo /run/current-system/sw/bin/nixos-rebuild switch --flake /home/alexandre/astronix#dev-dark
    '';
    lightModeScripts.rebuild = ''
      /run/wrappers/bin/sudo /run/current-system/sw/bin/nixos-rebuild switch --flake /home/alexandre/astronix#dev
    '';
  };
}
