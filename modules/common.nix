{ config, pkgs, inputs, ... }:

{
  imports = [
    ./zsh.nix
    "${inputs.nvim-config}/nix"
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  home-manager.useUserPackages = true;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8";
    LC_IDENTIFICATION = "fr_FR.UTF-8";
    LC_MEASUREMENT = "fr_FR.UTF-8";
    LC_MONETARY = "fr_FR.UTF-8";
    LC_NAME = "fr_FR.UTF-8";
    LC_NUMERIC = "fr_FR.UTF-8";
    LC_PAPER = "fr_FR.UTF-8";
    LC_TELEPHONE = "fr_FR.UTF-8";
    LC_TIME = "fr_FR.UTF-8";
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  users.users.alexandre = {
    isNormalUser = true;
    description = "alexandre";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        esc = "capslock";
        capslock = "esc";
      };
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    wget
    git
    uv
    zellij
    brave
  ];

  programs.lazygit.enable = true;
  services.openssh.enable = true;

  system.stateVersion = "25.11";
}
