# PLACEHOLDER. It lets the flake evaluate before the machine exists.
# After installing NixOS, replace this whole file on the machine with:
#
#   nixos-generate-config --show-hardware-config > hosts/gamix/hardware-configuration.nix
#
# The real file adds disk UUIDs, initrd modules, swap and CPU microcode.
# Until then, this uses the partition labels from the NixOS manual:
# `nixos` for / and `boot` for the ESP.
{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod" ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
