{ pkgs, ... }:

# ImPPG — sharpening (Lucy-Richardson deconvolution, unsharp masking) and
# tone-curve work on astronomical images, by Filip Szczerek. Not in nixpkgs, so
# we build it from source. CFITSIO, the OpenGL/GLEW back end and Lua scripting
# are on.
#
# FreeImage stays off on purpose: our nixpkgs dropped it over vulnerabilities,
# and parsing untrusted images is exactly what you don't want here. The cost is
# PNG/JPEG. ImPPG still handles BMP, 16-bit TIFF and FITS, which is what Siril
# and AutoStakkert hand it.
let
  imppg = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "imppg";
    version = "2.1.0";

    src = pkgs.fetchFromGitHub {
      owner = "GreatAttractor";
      repo = "imppg";
      rev = "v${finalAttrs.version}";
      hash = "sha256-FQboo3sv7n4aQjSifihMgEwNFohCs7U4l9vLra7Umrk=";
    };

    # config.cmake hard-sets USE_FREEIMAGE 1, so a cmake -D flag can't override it.
    postPatch = ''
      substituteInPlace config.cmake \
        --replace-fail "set(USE_FREEIMAGE 1)" "set(USE_FREEIMAGE 0)"
    '';

    # wrapGAppsHook3 puts GTK's GSettings schemas on XDG_DATA_DIRS. Without it
    # the gtk3 file chooser aborts as soon as you open a File dialog: our
    # GNOME-50 session ships only gtk4's org.gtk.Settings.FileChooser schema,
    # and the missing gtk3 one is a fatal g_error. The hook bundles imppg's own
    # copy, so the lookup works in any session.
    nativeBuildInputs = with pkgs; [ cmake pkg-config wxGTK32 wrapGAppsHook3 ];

    buildInputs = with pkgs; [
      boost
      wxGTK32      # provides wx-config; built with the gtk3 toolkit + OpenGL
      cfitsio      # USE_CFITSIO    — FITS files
      glew         # USE_OPENGL_BACKEND — GPU processing
      libGL
      lua5_4       # ENABLE_SCRIPTING
      gtk3                      # its GSettings schemas — see above
      gsettings-desktop-schemas # GTK reads these for chooser/font/theme
      # wx-config links -lSM -lICE -lX11 -lXext. List them so they land in
      # imppg's RPATH, or it won't launch.
      xorg.libSM
      xorg.libICE
      xorg.libX11
      xorg.libXext
    ];

    meta = with pkgs.lib; {
      description = "Image Post-Processor for sharpening/deconvolution of astronomical images";
      homepage = "https://github.com/GreatAttractor/imppg";
      license = licenses.gpl3Plus;
      platforms = platforms.linux;
      mainProgram = "imppg";
    };
  });
in
{
  environment.systemPackages = [ imppg ];
}
