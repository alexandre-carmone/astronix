{ inputs, ... }:

# Home-manager wiring (used as a NixOS module) and the per-user home config:
# Catppuccin Latte theming + Ghostty terminal + Zellij multiplexer.
{
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = { inherit inputs; };
  # Back up (rather than clobber) any pre-existing dotfiles home-manager wants to
  # manage, e.g. a zellij config.kdl generated on first run.
  home-manager.backupFileExtension = "backup";

  home-manager.users.alexandre = { pkgs, inputs, ... }: {
    imports = [ inputs.catppuccin.homeModules.catppuccin ];
    catppuccin.enable = true;
    catppuccin.flavor = "latte";
    catppuccin.accent = "blue";
    catppuccin.ghostty.enable = true;
    catppuccin.gtk.icon.enable = true;
    catppuccin.cursors.enable = true;
    catppuccin.zellij.enable = true;
    catppuccin.btop.enable = true;
    catppuccin.k9s.enable = true;
    programs.ghostty = {
      enable = true;
    };
    programs.zellij = {
      enable = true;
    };
    programs.btop = {
      enable = true;
    };
    programs.k9s = {
      enable = true;
    };
    home.pointerCursor.gtk.enable = true;
    home.stateVersion = "26.05";
  };
}
