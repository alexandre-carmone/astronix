{ config, pkgs, inputs, ... }:

{ imports = [
    ./zsh.nix
]; 
  nix.settings.experimental-features = [ "nix-command" "flakes" ];


  home-manager.useUserPackages = true;
  home-manager.useGlobalPkgs = true;
  home-manager.extraSpecialArgs = { inherit inputs; };

  home-manager.users.alexandre = { pkgs, inputs, ... }: {
    imports = [ inputs.catppuccin.homeModules.catppuccin ];
    catppuccin.enable = true;
    catppuccin.flavor = "latte";
    catppuccin.accent = "blue";
    catppuccin.ghostty.enable = true;
    catppuccin.gtk.icon.enable = true;
    catppuccin.cursors.enable = true;
    programs.ghostty = {
      enable = true;
    };
    home.pointerCursor.gtk.enable = true;
    home.stateVersion = "26.05";
  };

  boot.loader.systemd-boot.enable = true; boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Paris";

  i18n.defaultLocale = "en_US.UTF-8"; i18n.extraLocaleSettings = {
    LC_ADDRESS = "fr_FR.UTF-8"; LC_IDENTIFICATION = "fr_FR.UTF-8"; LC_MEASUREMENT = "fr_FR.UTF-8"; LC_MONETARY = "fr_FR.UTF-8"; LC_NAME = "fr_FR.UTF-8"; LC_NUMERIC = "fr_FR.UTF-8"; 
    LC_PAPER = "fr_FR.UTF-8"; LC_TELEPHONE = "fr_FR.UTF-8"; LC_TIME = "fr_FR.UTF-8";
  };

  services.pulseaudio.enable = false; security.rtkit.enable = true; services.pipewire = {
    enable = true; alsa.enable = true; alsa.support32Bit = true; pulse.enable = true;
  };

  users.users.alexandre = { isNormalUser = true; description = "alexandre"; extraGroups = [ "networkmanager" "wheel" "plugdev" ];
  };

  hardware.keyboard.qmk.enable = true;

  # splitkb.com Halcyon Elora rev2 (VIA/WebHID raw HID access for live config)
  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="8d1d", ATTRS{idProduct}=="a392", TAG+="uaccess"
  '';

  services.keyd = { enable = true; keyboards.default = {
      ids = [ "*" ]; settings.main = {
        esc = "capslock"; capslock = "esc";
      };
    };
  };
  programs.fzf.fuzzyCompletion = true;
  programs.neovim.enable = true;
  programs.neovim.defaultEditor = true;
  nixpkgs.config.allowUnfree = true;
  programs.nix-ld.enable = true;
  programs.chromium = {
    enable = true;
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
    ];
   };

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
 services.xserver.xkb = {
    layout = "us_qwerty-fr";
    extraLayouts = {
      us_qwerty-fr = {
        description = "US keyboard with French symbols (AltGr)";
        languages = [ "eng" ];
        symbolsFile = "${pkgs.qwerty-fr}/share/X11/xkb/symbols/us_qwerty-fr";
      };
    };
  };  
  programs.lazygit.enable = true;
  services.openssh.enable = true;

  system.stateVersion = "26.05";
}
