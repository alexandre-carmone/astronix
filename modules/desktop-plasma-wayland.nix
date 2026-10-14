{ config, pkgs, theme ? "light", ... }:

# Plasma 6 on Wayland for the gaming desktop.
# A real monitor, so none of the headless bits of desktop-plasma.nix:
# no fake EDID, no xrdp, no autologin.
# The Plasma module already runs SDDM on Wayland (with KWin) and makes the
# Wayland session the default. The Steam session from gaming.nix shows up
# next to it.
# Light/dark follows the `theme` flake argument, as in desktop-gnome.nix.
let
  preset = import ./theme.nix theme;
in
{
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;

  # Remove the default apps we don't use, as desktop-gnome.nix does.
  # What's left: Dolphin, Spectacle, Ark and System Settings.
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    konsole # Ghostty instead
    kate # nvim instead
    ktexteditor # only for kate
    elisa
    gwenview
    okular
    khelpcenter
    krdp
  ];

  # Disk usage and partitions. GNOME's Disk Usage Analyzer and Disks.
  programs.partition-manager.enable = true;
  environment.systemPackages = [ pkgs.kdePackages.filelight ];

  # KWin reads the layout from kxkbrc. That file is empty until the layout is
  # changed in System Settings. Until then, KWin falls back to
  # XKB_DEFAULT_LAYOUT. So the qwerty-fr layout from input.nix applies,
  # and System Settings can still override it.
  environment.sessionVariables.XKB_DEFAULT_LAYOUT = config.services.xserver.xkb.layout;

  # At login, apply the theme's Breeze color scheme and the Catppuccin accent.
  # It first turns off Plasma's own day/night switching. darkman does that job.
  # plasma-apply-colorscheme also recolours GTK apps and sets the portal color
  # scheme that Ghostty follows.
  #
  # This is a home-manager unit, not systemd.user.services. home-manager
  # restarts changed user units on a switch. So when darkman rebuilds into
  # gamix-dark, the running session changes color right away.
  # RemainAfterExit keeps the unit active, so it can be restarted.
  home-manager.users.alexandre.systemd.user.services.plasma-color-scheme = {
    Unit = {
      Description = "Apply the ${theme} Plasma color scheme";
      PartOf = [ "graphical-session.target" ];
      # After kded. Its gtkconfig module recolours GTK on the change.
      After = [ "graphical-session.target" "plasma-kded6.service" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      # With --accent-color, the tool ignores a scheme name. Hence two calls.
      ExecStart = toString (pkgs.writeShellScript "plasma-color-scheme" ''
        ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals \
          --group KDE --key AutomaticLookAndFeel false
        ${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-colorscheme ${preset.plasmaColorScheme}
        ${pkgs.kdePackages.plasma-workspace}/bin/plasma-apply-colorscheme --accent-color '${preset.mauve}'
      '');
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
