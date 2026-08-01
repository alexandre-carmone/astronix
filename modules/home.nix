{ inputs, ... }:

# Home-manager wiring (used as a NixOS module) and the per-user home config:
# Catppuccin Latte theming + Ghostty terminal.
{
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = { inherit inputs; };

  home-manager.users.alexandre = { pkgs, inputs, ... }: {
    imports = [ inputs.catppuccin.homeModules.catppuccin ];
    catppuccin.enable = true;
    catppuccin.flavor = "latte";
    catppuccin.accent = "blue";
    catppuccin.ghostty.enable = true;
    catppuccin.gtk.icon.enable = true;
    catppuccin.cursors.enable = true;
    programs.ghostty = {
      enable = true;
    };
    home.pointerCursor.gtk.enable = true;
    home.stateVersion = "26.05";
  };
}
