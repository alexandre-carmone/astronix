{ pkgs, ... }:

# ImPPG, by Filip Szczerek. Not in nixpkgs, so we build it from source.
# Sharpening (Lucy-Richardson deconvolution, unsharp mask) and tone curves
# for astronomical images.
# Enabled: CFITSIO, the OpenGL/GLEW back end and Lua scripting.
#
# FreeImage stays off on purpose. Our nixpkgs dropped it for security issues,
# and it would parse untrusted images. The cost: no PNG or JPEG.
# ImPPG still reads BMP, 16-bit TIFF and FITS. That is what Siril and
# AutoStakkert give it.
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

    # config.cmake forces USE_FREEIMAGE 1. A cmake -D flag can't override it.
    postPatch = ''
      substituteInPlace config.cmake \
        --replace-fail "set(USE_FREEIMAGE 1)" "set(USE_FREEIMAGE 0)"
    '';

    # wrapGAppsHook3 adds GTK's GSettings schemas to XDG_DATA_DIRS.
    # Without it, the gtk3 file chooser crashes when you open a File dialog.
    # Our GNOME 50 session only has gtk4's org.gtk.Settings.FileChooser
    # schema. The missing gtk3 one is a fatal g_error.
    # The hook gives imppg its own copy, so it works in any session.
    nativeBuildInputs = with pkgs; [ cmake pkg-config wxwidgets_3_2 wrapGAppsHook3 ];

    buildInputs = with pkgs; [
      boost
      wxwidgets_3_2 # provides wx-config. Built with gtk3 and OpenGL
      cfitsio      # USE_CFITSIO    — FITS files
      glew         # USE_OPENGL_BACKEND — GPU processing
      libGL
      lua5_4       # ENABLE_SCRIPTING
      gtk3                      # its GSettings schemas — see above
      gsettings-desktop-schemas # GTK reads these for chooser/font/theme
      # wx-config links -lSM -lICE -lX11 -lXext. List them here so they end
      # up in imppg's RPATH. Otherwise it won't start.
      libsm
      libice
      libx11
      libxext
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
