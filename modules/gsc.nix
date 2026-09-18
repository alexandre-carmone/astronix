{ pkgs, ... }:

# GSC — the HST Guide Star Catalog, both the `gsc` query tool and the ~9,500
# region files it reads. Not in nixpkgs; elsewhere it arrives as the `gsc` and
# `gsc-data` packages from the INDI PPA, which is why the CCD Simulator has
# stars out of the box on Ubuntu and none here.
#
# This module exists purely for INDI's CCD Simulator. indi_simulator_ccd draws
# its fake star field by shelling out to the catalog (ccd_simulator.cpp):
#
#   popen("gsc -c <ra> <dec> -r <radius> -m 0 <mag> -n 3000")
#
# With no `gsc` on PATH that popen() still *succeeds* — /bin/sh starts fine and
# exits 127 — so the driver parses zero stars and logs the misleading
#
#   "No stars found in field -- check gsc catalog coverage for this region."
#
# instead of its "Error launching gsc" branch. Frames then hold sky glow and
# noise but not one star, and Ekos' align/guide/focus have nothing to chew on.
#
# gsc.c finds the catalog through $GSCDAT, falling back to an argv[0] heuristic
# that only fires for a literal /usr/bin/gsc, then to a hard-coded
# /usr/share/GSC — none of which exist here. So we wrap the binary to point
# GSCDAT at its own store path. $GSCBIN is deliberately left unset: gsc derives
# it as $GSCDAT/bin, which is exactly where CMake drops regions.bin/regions.ind.
# Wrapping beats a global environment.variables entry because the lookup happens
# in whatever environment indiserver was started with — possibly a remote one —
# whereas the wrapper travels with the binary on PATH.
#
# Upstream keeps the catalog in the source tree, so both src and the installed
# output weigh ~235 MB. That is the whole cost of this module.
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
    # defaults to -std=gnu23, which made the first two hard errors, so pin the
    # dialect the code was written for rather than deafen the diagnostics
    # one -Wno- flag at a time.
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
