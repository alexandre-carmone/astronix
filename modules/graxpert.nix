{ pkgs, ... }:

# GraXpert, by Steffen Hirtle. Not in nixpkgs.
# Gradient removal and AI denoising for astronomical images.
#
# Upstream ships only a cx_Freeze bundle: a frozen CPython 3.10 with every
# dependency as a .so. They look for libX11, libGL and libstdc++ in FHS
# paths, which NixOS lacks. autoPatchelfHook fixes their interpreter and
# RPATHs, so no FHS env or steam-run is needed.
#
# The AI models are not bundled. GraXpert downloads them on first use to
# ~/.local/share/GraXpert. Preferences live in ~/.config/GraXpert.
let
  graxpert = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "graxpert";
    version = "3.0.2";

    src = pkgs.fetchurl {
      url = "https://github.com/Steffenhir/GraXpert/releases/download/${finalAttrs.version}/graxpert-linux-amd64.zip";
      hash = "sha256-CnNkwzBLoZ8SIx1TPICylAVNZVjVTs2BZo5N7EkJJYg=";
    };

    sourceRoot = "GraXpert-linux";

    nativeBuildInputs = with pkgs; [
      unzip
      autoPatchelfHook
      makeWrapper
      copyDesktopItems
    ];

    buildInputs = with pkgs; [
      stdenv.cc.cc.lib # libstdc++, libgcc_s
      zlib
      glib
      libGL # the bundled opencv links libGL.so.1 at import time
      libx11 # tkinter/tk
      libxext
      libxrender
      libxft
      libsm # opencv's bundled Qt xcb platform plugin
      libice
    ];

    # The bundled onnxruntime has CUDA and TensorRT providers, but not their
    # libraries. So they never load. Inference runs on CPU and logs one
    # "Init provider bridge failed" line. Leave them unresolved instead of
    # pulling in all of CUDA for dead code.
    autoPatchelfIgnoreMissingDeps = [
      "libcuda.so.1"
      "libcudart.so*"
      "libcublas*.so*"
      "libcudnn*.so*"
      "libcufft.so*"
      "libcurand.so*"
      "libnvinfer*.so*"
      "libnvonnxparser.so*"
    ];

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/opt/graxpert"
      cp -r GraXpert lib share "$out/opt/graxpert/"
      chmod +x "$out/opt/graxpert/GraXpert"
      install -Dm644 frozen_application_license.txt \
        "$out/share/licenses/graxpert/frozen_application_license.txt"

      # customtkinter copies its fonts to ~/.fonts at every start.
      # The copies keep the store's read-only mode. So the second start fails
      # with EACCES, and the UI falls back to "circle_shapes" drawing.
      # Make the copies writable again before launch.
      mkdir -p "$out/libexec"
      cat > "$out/libexec/graxpert-fix-fonts" <<'EOF'
      #!/bin/sh
      fonts="@fontdir@"
      for font in "$fonts"/* "$fonts"/*/*; do
        [ -f "$font" ] || continue
        target="$HOME/.fonts/''${font##*/}"
        [ -e "$target" ] && chmod u+w "$target"
      done
      exit 0
      EOF
      substituteInPlace "$out/libexec/graxpert-fix-fonts" \
        --replace-fail '@fontdir@' "$out/opt/graxpert/lib/customtkinter/assets/fonts"
      chmod +x "$out/libexec/graxpert-fix-fonts"

      makeWrapper "$out/opt/graxpert/GraXpert" "$out/bin/graxpert" \
        --run "$out/libexec/graxpert-fix-fonts"

      # Icon.ico holds a single 256x256 PNG.
      # Extract it for desktops that can't read .ico.
      iconOffset=$(od -An -tu4 -j 18 -N 4 Icon.ico | tr -d ' ')
      dd if=Icon.ico of=graxpert.png bs=1 skip="$iconOffset" status=none
      install -Dm644 graxpert.png \
        "$out/share/icons/hicolor/256x256/apps/graxpert.png"

      runHook postInstall
    '';

    desktopItems = [
      (pkgs.makeDesktopItem {
        name = "graxpert";
        exec = "graxpert %f";
        icon = "graxpert";
        desktopName = "GraXpert";
        comment = "Remove gradients and noise from astronomical images";
        categories = [ "Graphics" "2DGraphics" "RasterGraphics" ];
        mimeTypes = [ "image/fits" "image/tiff" "image/png" ];
      })
    ];

    meta = with pkgs.lib; {
      description = "Gradient removal and AI denoising for astronomical images";
      homepage = "https://github.com/Steffenhir/GraXpert";
      license = licenses.gpl3Only;
      platforms = [ "x86_64-linux" ];
      mainProgram = "graxpert";
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
    };
  });
in
{
  environment.systemPackages = [ graxpert ];
}
