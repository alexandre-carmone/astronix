{ ... }:

# Home-manager service that flips the whole system between the light and dark
# variants at sunrise/sunset. Because the Catppuccin TUI themes are baked into
# the home-manager generation (read-only /nix/store symlinks), the switch is a
# `nixos-rebuild switch` to the sibling flake output (`#dev` vs `#dev-dark`)
# rather than a runtime dconf/file tweak.
#
# The rebuild needs root: a matching NOPASSWD sudo rule restricted to these two
# exact commands lives in hosts/dev/configuration.nix. Ghostty additionally
# follows the color-scheme natively (see home.nix), so the terminal recolours
# instantly without waiting for the rebuild to finish.
{
  services.darkman = {
    enable = true;
    settings = {
      # Sunrise/sunset are computed from these coordinates. Fixed coords avoid
      # pulling in the geoclue daemon. Adjust to your location (default: Paris).
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
