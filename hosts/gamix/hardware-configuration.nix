# PLACEHOLDER, so the flake evaluates before the machine exists. Replace this
# whole file on the machine, after installing NixOS, with:
#
#   nixos-generate-config --show-hardware-config > hosts/gamix/hardware-configuration.nix
#
# The generated one adds the real disk UUIDs, initrd modules, swap and CPU
# microcode. Until then this assumes the partition labels from the NixOS
# manual's install steps: `nixos` for / and `boot` for the ESP.
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
