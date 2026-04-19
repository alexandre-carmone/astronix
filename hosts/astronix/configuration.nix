# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Paris";

  # Select internationalisation properties.
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

  # Enable the X11 windowing system.
  # You can disable this if you're only using the Wayland session.

  # Enable the KDE Plasma Desktop Environment.
services.displayManager.defaultSession = "plasmax11";
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = false;
  };
services.displayManager.autoLogin = {
  enable = true;
  user = "alexandre";
};
  services.xrdp = {
    enable = true;
    defaultWindowManager = "startplasma-x11";  # X11 session for xrdp
    openFirewall = true;                       # opens TCP 3389
  };
 services.desktopManager.plasma6.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.alexandre = {
    isNormalUser = true;
    description = "alexandre";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    #  thunderbird
    ];
  };

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

services.xserver = {
    enable = true;
    videoDrivers = [ "dummy" ];

    monitorSection = ''
      HorizSync   15.0 - 200.0
      VertRefresh 15.0 - 200.0
      Modeline "1920x1080" 173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync
      Modeline "2560x1440" 241.50 2560 2608 2640 2720 1440 1443 1448 1481 +hsync -vsync
      Modeline "1680x1050" 146.25 1680 1784 1960 2240 1050 1053 1059 1089 -hsync +vsync
      Option "PreferredMode" "1920x1080"
    '';

    deviceSection = ''
      VideoRam 256000
    '';

    screenSection = ''
      DefaultDepth 24
      SubSection "Display"
        Depth 24
        Modes "1920x1080" "2560x1440" "1680x1050"
        Virtual 2560 1440
      EndSubSection
    '';
  };  # List packages installed in system profile. To search, run:
  # $ nix search wget
systemd.services.headless-resolution = {
  description = "Force 1920x1080 on DUMMY0";
  after = [ "display-manager.service" ];
  wantedBy = [ "graphical.target" ];
  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
    # SDDM tourne sur :0 avec son propre xauth
    Environment = [
      "DISPLAY=:0"
      "XAUTHORITY=/run/sddm/xauth"  # ajustez si nécessaire
    ];
    ExecStart = pkgs.writeShellScript "force-resolution" ''
      # Attend que Xorg soit prêt
      for i in $(seq 1 30); do
        ${pkgs.xorg.xrandr}/bin/xrandr >/dev/null 2>&1 && break
        sleep 1
      done
      XAUTH=$(ls /run/sddm/xauth_* 2>/dev/null | head -1)
      export XAUTHORITY="$XAUTH"
      ${pkgs.xorg.xrandr}/bin/xrandr --newmode "1920x1080_60" 173.00 1920 2048 2248 2576 1080 1083 1088 1120 -hsync +vsync || true
      ${pkgs.xorg.xrandr}/bin/xrandr --addmode DUMMY0 "1920x1080_60" || true
      ${pkgs.xorg.xrandr}/bin/xrandr --output DUMMY0 --mode "1920x1080_60" || true
    '';
  };
};

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    ghostty
    uv
    rustdesk-flutter
    kstars
    phd2
    indi-full
    indi-3rdparty.indi-toupbase
    git

  ];

networking.firewall = {
    allowedTCPPorts = [ 21115 21116 21117 21118 21119 ];
    allowedUDPPorts = [ 21116 ];
  };

  users.users.alexandre.shell = pkgs.zsh;
	environment.shells = with pkgs; [ zsh ];
   programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      edit = "sudo -e";
      update = "sudo nixos-rebuild switch";
    };

    histSize = 10000;
    histFile = "$HOME/.zsh_history";
    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
    ];
  };

programs.zsh.ohMyZsh = {
    enable = true;
    plugins = [ "git" "zsh-interactive-cd" "history-substring-search"];
    theme = "skaro";
  };
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

}
