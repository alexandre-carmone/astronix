{ lib, pkgs, ... }:

# Keyboard/input concerns: QMK support, esc<->capslock swap, raw HID access for
# live keyboard configuration, and the qwerty-fr xkb layout.
{
  hardware.keyboard.qmk.enable = true;

  # splitkb.com Halcyon Elora rev2 (VIA/WebHID raw HID access for live config)
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
    # mkDefault so a host can override the session layout (the headless Plasma
    # host pins plain "us" in modules/desktop-plasma.nix).
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
