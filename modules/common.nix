{ pkgs, ... }:

# Base configuration shared by every host. Pulls in the per-concern modules and
# holds the truly-common bits: nix/flakes, boot, networking, the user account,
# and the base CLI toolset.
{
  imports = [
    ./locale.nix
    ./audio.nix
    ./input.nix
    ./home.nix
    ./zsh.nix
  ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  users.users.alexandre = {
    isNormalUser = true;
    description = "alexandre";
    extraGroups = [ "networkmanager" "wheel" "plugdev" ];
  };

  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;

  programs.fzf.fuzzyCompletion = true;
  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;
  programs.lazygit.enable = true;

  programs.chromium = {
    enable = true;
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
    ];
  };

  programs.firefox.enable = true;
  services.printing.enable = true;
  services.openssh.enable = true;

  environment.systemPackages = with pkgs; [
    fd
    ripgrep
    wget
    unzip
    git
    uv
    cargo
    zellij
    brave
    lua
    luarocks
    qwerty-fr
    lazygit
    btop
  ];

  system.stateVersion = "26.05";
}
