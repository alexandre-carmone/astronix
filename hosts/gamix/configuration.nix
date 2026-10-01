{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./nvidia.nix
    ../../modules/common.nix
    ../../modules/astro.nix
    ../../modules/desktop-gnome.nix
    ../../modules/darkman.nix
    ../../modules/gaming.nix
  ];

  networking.hostName = "gamix";

  environment.systemPackages = with pkgs; [
    # For the LazyVim config in ~/.config/nvim: nvim-treesitter compiles its
    # grammars and Mason builds some servers.
    gcc
    gnumake
  ];
}
