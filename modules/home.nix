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
    catppuccin.flavor = "mocha";
    catppuccin.accent = "mauve";
    catppuccin.ghostty.enable = true;
    catppuccin.gtk.icon.enable = true;
    catppuccin.cursors.enable = true;
    catppuccin.zellij.enable = true;
    catppuccin.btop.enable = true;
    catppuccin.k9s.enable = true;
    catppuccin.lazygit.enable = true;
    programs.ghostty = {
      enable = true;
    };
    programs.zellij = {
      enable = true;
      # Move Zellij's "Move" mode off Ctrl+h (clashes with nvim's <C-h> split
      # navigation) onto Ctrl+m. Layered on top of the compiled-in defaults, so
      # we only unbind Ctrl+h and add Ctrl+m in the two places the default uses it.
      # NOTE: Ctrl+m == Enter at the byte level; this only stays distinct because
      # Ghostty + Zellij both speak the Kitty keyboard protocol.
      extraConfig = ''
        keybinds {
          shared_except "move" "locked" {
            unbind "Ctrl h"
            bind "Ctrl m" { SwitchToMode "Move"; }
          }
          move {
            unbind "Ctrl h"
            bind "Ctrl m" { SwitchToMode "Normal"; }
          }
        }
      '';
    };
    programs.btop = {
      enable = true;
    };
    programs.k9s = {
      enable = true;
    };
    programs.lazygit = {
      enable = true;
    };
    home.pointerCursor.gtk.enable = true;
    home.stateVersion = "26.05";
  };
}
