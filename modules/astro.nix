{ pkgs, ... }:

# Astrophotography stack shared by both hosts: INDI drivers (via udev) and the
# desktop apps used to capture/process (kstars, phd2, siril, gimp) plus rustdesk
# for remote control of the rig.
{
  services.udev.packages = [
    pkgs.indi-full
    pkgs.indi-3rdparty.indi-toupbase
    pkgs.indi-3rdparty.indi-playerone
  ];

  environment.systemPackages = with pkgs; [
    kstars
    phd2
    siril
    gimp
    rustdesk-flutter
    indi-full
    indi-3rdparty.indi-toupbase
    indi-3rdparty.indi-playerone
  ];

  # Serial access for INDI-controlled mounts/focusers.
  users.users.alexandre.extraGroups = [ "dialout" ];
}
