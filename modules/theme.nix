# Maps a theme name ("light" or "dark") to the settings that differ.
# One source of truth for:
#   - GNOME dconf, in desktop-gnome.nix
#   - the Plasma color scheme, in desktop-plasma-wayland.nix
#   - the Catppuccin flavor, in home.nix
# Usage: `let preset = import ./theme.nix theme; in preset.flavor`.
theme:
let
  isDark = theme == "dark";
in
{
  # Catppuccin flavor for the TUI apps (btop, zellij, k9s, lazygit).
  flavor = if isDark then "mocha" else "latte";
  # GNOME's global light/dark toggle.
  colorScheme = if isDark then "prefer-dark" else "prefer-light";
  # Only the light scheme needs this. With dark, GNOME already draws light
  # text. See desktop-gnome.nix.
  forceLightText = !isDark;
  # Plasma's color scheme.
  plasmaColorScheme = if isDark then "BreezeDark" else "BreezeLight";
  # Catppuccin mauve, the accent set in home.nix. Plasma takes any color.
  # GNOME only has named accents, so it gets "purple".
  mauve = if isDark then "#cba6f7" else "#8839ef";
}
