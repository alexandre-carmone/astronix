# Replace this file with the output of `nixos-generate-config --show-hardware-config`
# run on the target `dev` machine.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # fileSystems."/" = { device = "/dev/disk/by-uuid/REPLACE-ME"; fsType = "ext4"; };
  # fileSystems."/boot" = { device = "/dev/disk/by-uuid/REPLACE-ME"; fsType = "vfat"; };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
