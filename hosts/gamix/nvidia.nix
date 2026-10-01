{ pkgs, ... }:

# NVIDIA card driving the display directly (no iGPU, no PRIME). Turing or
# newer, so the open kernel modules, which NVIDIA recommends for those cards.
#
# The nixpkgs module already turns on, for this driver: modesetting, its
# fbdev (GNOME Wayland needs both), VA-API through nvidia-vaapi-driver, and
# the kernel suspend notifier. They aren't repeated here.
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  hardware.nvidia = {
    # No default from 560 on: the module asserts it is set either way.
    open = true;
    # Saves VRAM across suspend. Without it, GNOME Wayland comes back from
    # sleep with corrupted or black windows.
    powerManagement.enable = true;
    nvidiaSettings = true;
  };

  environment.systemPackages = [
    pkgs.nvtopPackages.nvidia # GPU load, VRAM, temperature
  ];
}
