{ inputs, theme ? "light", ... }:

# Home-manager, wired in as a NixOS module, plus the user's home config:
# Catppuccin theming (the flavor follows `theme`), Ghostty and Zellij.
let
  preset = import ./theme.nix theme;
in
{
  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = { inherit inputs; };
  # Back up the dotfiles home-manager wants to manage instead of clobbering
  # them, e.g. a zellij config.kdl written on first run.
  home-manager.backupFileExtension = "backup";

  home-manager.users.alexandre = { pkgs, inputs, ... }: {
    imports = [ inputs.catppuccin.homeModules.catppuccin ./darkman.nix ];
    catppuccin.enable = true;
    catppuccin.flavor = preset.flavor;
    catppuccin.accent = "mauve";
    # Ghostty themes itself (below) so it follows the system color-scheme
    # live, instead of being pinned to one flavor at build time.
    catppuccin.ghostty.enable = false;
    catppuccin.gtk.icon.enable = true;
    catppuccin.cursors.enable = true;
    catppuccin.zellij.enable = true;
    catppuccin.btop.enable = true;
    catppuccin.k9s.enable = true;
    catppuccin.lazygit.enable = true;
    programs.ghostty = {
      enable = true;
      # Ghostty ships both variants and picks the one matching the OS
      # preference, recolouring the moment it changes.
      settings.theme = "light:Catppuccin Latte,dark:Catppuccin Mocha";
    };
    programs.zellij = {
      enable = true;
      # Move Zellij's "Move" mode from Ctrl+h to Ctrl+m. Ctrl+h clashes with
      # nvim's split navigation. This sits on top of the defaults, so it only
      # touches the two places that used Ctrl+h.
      # Ctrl+m is Enter at the byte level. It stays distinct only because
      # Ghostty and Zellij both speak the Kitty keyboard protocol.
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
