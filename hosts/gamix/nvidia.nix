{ pkgs, ... }:

# The NVIDIA card drives the display directly. No iGPU, no PRIME.
# It is Turing or newer, so it uses the open kernel modules.
# NVIDIA recommends them for these cards.
#
# The nixpkgs module already enables, for this driver:
#   - modesetting and fbdev (Plasma Wayland needs both)
#   - VA-API through nvidia-vaapi-driver
#   - the kernel suspend notifier
# So they are not repeated here.
{
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  hardware.nvidia = {
    # No default since driver 560. It must be set explicitly.
    open = true;
    # Saves VRAM across suspend.
    # Without it, Wayland wakes up with corrupted or black windows.
    powerManagement.enable = true;
    nvidiaSettings = true;
  };

  environment.systemPackages = [
    pkgs.nvtopPackages.nvidia # GPU load, VRAM, temperature
  ];
}
