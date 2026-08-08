{ pkgs, ... }:

# ImPPG (Image Post-Processor) — open-source tool for sharpening (Lucy-Richardson
# deconvolution + unsharp masking) and tone-curve adjustment of astronomical
# images, by Filip Szczerek (GreatAttractor). Not in nixpkgs, so we build it from
# source with CMake. Optional features enabled: CFITSIO (FITS), the OpenGL/GLEW
# GPU back end, and Lua scripting. FreeImage is intentionally left OFF — it was
# dropped from our nixpkgs for numerous vulnerabilities, and it's exactly the
# untrusted-image-parsing surface you don't want in a photo tool. Without it,
# ImPPG still reads/writes BMP, 16-bit TIFF (mono/RGB) and FITS — the formats it
# gets from Siril/AutoStakkert — but not PNG/JPEG. Its install target ships the
# binary, shaders, images, docs, translations and a .desktop file.
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

    # wrapGAppsHook3 wraps the binary to prepend GTK's GSettings schemas (and
    # GIO modules) to XDG_DATA_DIRS. Without it, imppg's gtk3 file chooser aborts
    # the moment you open a File dialog: our GNOME-50 session only exposes gtk4's
    # `org.gtk.Settings.FileChooser` schema, so gtk3's chooser can't find a valid
    # schema and GSettings raises a fatal g_error. The hook bundles imppg's own
    # matching gtk3 schemas so the lookup succeeds regardless of the session.
    nativeBuildInputs = with pkgs; [ cmake pkg-config wxGTK32 wrapGAppsHook3 ];

    buildInputs = with pkgs; [
      boost
      wxGTK32      # provides wx-config; built with the gtk3 toolkit + OpenGL
      cfitsio      # USE_CFITSIO    — FITS files
      glew         # USE_OPENGL_BACKEND — GPU processing
      libGL
      lua5_4       # ENABLE_SCRIPTING
      gtk3                       # its GSettings schemas (esp. FileChooser) — see above
      gsettings-desktop-schemas # GTK reads these for chooser/font/theme settings
      # wxWidgets links -lSM -lICE -lX11 -lXext (X session management) via
      # wx-config; add them so they land in imppg's RPATH, else it won't launch.
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
