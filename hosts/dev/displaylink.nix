{config, pkgs, ...}:

# DisplayLink dock: the evdi kernel module plus the DisplayLinkManager daemon,
# started at boot.
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
    # Start once udev has done its work.
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
