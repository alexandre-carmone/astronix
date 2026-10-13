{ pkgs, ... }:

# Gaming: Steam with Proton-GE, gamescope, GameMode and MangoHud.
# Heroic for Epic and GOG.
# Steam enables 32-bit graphics and the udev rules for Steam controllers
# and the Index on its own.
{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    # Adds a "Steam" session to the GDM login screen.
    # Big Picture, fullscreen under gamescope. For the couch.
    gamescopeSession.enable = true;
    # Proton-GE shows up under Steam > Compatibility next to Valve's Protons.
    # Updates come from nixpkgs, not ProtonUp.
    extraCompatPackages = [ pkgs.proton-ge-bin ];
    protontricks.enable = true;
  };

  # Keep capSysNice off. Steam runs games in a bwrap sandbox with
  # no_new_privs, so the capability is never granted. Launched from Steam,
  # gamescope then exits with "failed to inherit capabilities".
  programs.gamescope.enable = true;

  # Games opt in with `gamemoderun %command%` in their Steam launch options.
  # The gamemode group lets it change the CPU governor and GPU clocks
  # through polkit, without a password prompt.
  programs.gamemode.enable = true;
  users.users.alexandre.extraGroups = [ "gamemode" ];

  environment.systemPackages = with pkgs; [
    mangohud # FPS/frametime overlay: `mangohud %command%`
    heroic
  ];
}
