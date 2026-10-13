{ lib, pkgs, ... }:

# Keyboard: QMK, Esc/Caps Lock swap, raw HID for live config, qwerty-fr layout.
{
  hardware.keyboard.qmk.enable = true;

  # splitkb.com Halcyon Elora rev2. Raw HID access for live config (VIA/WebHID).
  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="8d1d", ATTRS{idProduct}=="a392", TAG+="uaccess"
  '';

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        esc = "capslock";
        capslock = "esc";
      };
    };
  };

  services.xserver.xkb = {
    # mkDefault, so a host can override it. desktop-plasma.nix sets plain "us".
    layout = lib.mkDefault "us_qwerty-fr";
    extraLayouts = {
      us_qwerty-fr = {
        description = "US keyboard with French symbols (AltGr)";
        languages = [ "eng" ];
        symbolsFile = "${pkgs.qwerty-fr}/share/X11/xkb/symbols/us_qwerty-fr";
      };
    };
  };
}
