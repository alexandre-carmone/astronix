{ pkgs, ... }:

# Wine and friends, for Windows apps on the dev workstation.
#   - wineWowPackages.stable: 32- and 64-bit Wine
#   - winetricks: installs runtime deps
#   - bottles: a GUI for per-app prefixes
# Most graphical apps need 32-bit OpenGL.
{
  hardware.graphics.enable32Bit = true;

  # bottles needs python `patool`. Its tests fail in our nixpkgs: the build
  # sandbox lacks the bzip2/xz/lzma tools they call. Skip the tests.
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pyfinal: pyprev: {
          patool = pyprev.patool.overridePythonAttrs (_: {
            doCheck = false;
            doInstallCheck = false;
          });
        })
      ];
    })
  ];

  environment.systemPackages = with pkgs; [
    wineWowPackages.stable
    winetricks
    bottles
  ];
}
