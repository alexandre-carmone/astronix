{ pkgs, ... }:

# Wine + tooling for running Windows applications on the dev workstation.
# wineWowPackages.stable provides both 32- and 64-bit Wine; winetricks handles
# runtime deps/tweaks; bottles is a GUI for managing per-app Wine prefixes.
# 32-bit OpenGL is required for most graphical Windows apps to render.
{
  hardware.graphics.enable32Bit = true;

  # bottles depends on the python `patool` library, whose test suite fails in
  # the pinned nixpkgs (the build sandbox lacks the bzip2/xz/lzma helpers the
  # tests shell out to). The tests are not needed at runtime, so skip them.
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
