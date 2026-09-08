# Pure mapping: a theme name ("light" | "dark") -> the concrete settings that
# differ between the two schemes. Imported by both layers so the light/dark
# choice has a single source of truth:
#   - the NixOS layer (GNOME dconf) in desktop-gnome.nix
#   - the home-manager layer (Catppuccin flavor) in home.nix
# Usage: `let preset = import ./theme.nix theme; in preset.flavor` etc.
theme:
let
  isDark = theme == "dark";
in
{
  # Catppuccin flavor driving all the TUI apps (btop, zellij, k9s, lazygit).
  flavor = if isDark then "mocha" else "latte";
  # GNOME's global light/dark toggle.
  colorScheme = if isDark then "prefer-dark" else "prefer-light";
  # blur-my-shell keeps the panel text light only under the light scheme (see
  # the note in desktop-gnome.nix); under dark GNOME already draws light text.
  forceLightText = !isDark;
  # Wallpapers per scheme. PLACEHOLDERS — point at real Siril/ImPPG exports.
  # Keep both keys even if identical for now.
  wallpaperLight = "file:///home/alexandre/Pictures/wallpapers/master_noth_american.png";
  wallpaperDark = "file:///home/alexandre/Pictures/wallpapers/master_noth_american.png";
}
