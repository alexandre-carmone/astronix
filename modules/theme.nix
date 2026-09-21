# Maps a theme name ("light" or "dark") to the settings that differ between
# the two. One source of truth for both layers:
#   - GNOME dconf, in desktop-gnome.nix
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
  # Only the light scheme needs this; under dark GNOME already draws light
  # text. See desktop-gnome.nix.
  forceLightText = !isDark;
  # One wallpaper per scheme. Keep both keys, even when they match.
  wallpaperLight = "file:///home/alexandre/Pictures/wallpapers/master_noth_american.png";
  wallpaperDark = "file:///home/alexandre/Pictures/wallpapers/master_noth_american.png";
}
