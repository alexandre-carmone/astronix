{config, pkgs, ...}:

# DisplayLink dock.
# Loads the evdi kernel module and starts DisplayLinkManager at boot.
{
  environment.systemPackages = with pkgs; [
    displaylink
  ];
  boot.extraModulePackages = [ config.boot.kernelPackages.evdi ];
  boot.initrd.kernelModules = ["evdi"];

  services.xserver.videoDrivers = [ "displaylink" ];
  # For GNOME.
  systemd.services.dlm.wantedBy = [ "multi-user.target" ];
  systemd.services.displaylink-server = {
    enable = true;
    # Start after udev.
    requires = [ "systemd-udevd.service" ];
    after = [ "systemd-udevd.service" ];
    wantedBy = [ "multi-user.target" ]; # start at boot
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.displaylink}/bin/DisplayLinkManager";
      User = "root";
      Group = "root";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
