{ pkgs, ... }:

# GSC — the HST Guide Star Catalog: the `gsc` query tool and the ~9,500 region
# files it reads. Not in nixpkgs. Elsewhere it comes from the INDI PPA, which
# is why the CCD Simulator shows stars on Ubuntu and none here.
#
# This module exists only for that simulator. indi_simulator_ccd draws its fake
# star field by shelling out to the catalog:
#
#   popen("gsc -c <ra> <dec> -r <radius> -m 0 <mag> -n 3000")
#
# With no `gsc` on PATH that popen() still succeeds (sh exits 127), so the
# driver reads zero stars and logs "No stars found in field" instead of "Error
# launching gsc". Frames then carry sky glow and noise but not one star, and
# Ekos' align, guide and focus have nothing to work with.
#
# gsc finds the catalog through $GSCDAT, else an argv[0] heuristic that only
# fires for /usr/bin/gsc, else /usr/share/GSC. None exist here, so we wrap the
# binary and point GSCDAT at its own store path. $GSCBIN stays unset: gsc
# derives it as $GSCDAT/bin, which is where CMake drops regions.bin. A wrapper
# beats environment.variables because the lookup happens wherever indiserver
# was started, possibly on another machine, while the wrapper follows the
# binary on PATH.
#
# The catalog ships inside the source tree, so src and output both weigh
# ~235 MB. That is the whole cost of this module.
let
  gsc = pkgs.stdenv.mkDerivation {
    pname = "gsc";
    version = "1.3-unstable-2026-09-08";

    src = pkgs.fetchgit {
      url = "https://git.launchpad.net/gsc";
      rev = "a0405c4257096a2a53763def1a617c15953ab7ff";
      hash = "sha256-nkdxHRZgFFfejdp10J+kafwVJt+G7o3Fq/Ly06FAV3s=";
    };

    nativeBuildInputs = with pkgs; [ cmake makeWrapper ];

    # 1990s C: K&R definitions, implicit declarations, `void main`. GCC 15
    # defaults to -std=gnu23 and turns the first two into hard errors, so pin
    # the dialect the code was written for instead of silencing warnings one
    # flag at a time.
    env.NIX_CFLAGS_COMPILE = "-std=gnu89";

    postInstall = ''
      wrapProgram "$out/bin/gsc" --set GSCDAT "$out/share/GSC"
    '';

    meta = with pkgs.lib; {
      description = "HST Guide Star Catalog and its query tool, used by INDI's CCD Simulator";
      homepage = "https://launchpad.net/gsc";
      license = licenses.gpl2Plus;
      platforms = platforms.linux;
      mainProgram = "gsc";
    };
  };
in
{
  environment.systemPackages = [ gsc ];
}
