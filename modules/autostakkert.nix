{ pkgs, ... }:

# AutoStakkert!4 — proprietary Windows "lucky imaging" stacking software for
# planetary/lunar/solar astrophotography (freeware, by Emil Kraaikamp). It ships
# as a portable zip (a single .exe plus FreeImage.dll), so we fetch it and run
# it under Wine in an isolated prefix. The program files are copied into the
# (writable) prefix on each launch because AutoStakkert writes settings next to
# its exe and the nix store is read-only.
let
  autostakkert = pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "autostakkert";
    version = "4.0.13";

    src = pkgs.fetchurl {
      url = "https://www.astrokraai.nl/software/AutoStakkert_${finalAttrs.version}_x64.zip";
      hash = "sha256-loOOUNRTa+X2dcSZkllG0f/gUGyCT+L5zTrvwvSxmFk=";
    };

    nativeBuildInputs = with pkgs; [ unzip makeWrapper icoutils ];

    unpackPhase = ''
      runHook preUnpack
      mkdir -p source
      unzip -q "$src" -d source
      runHook postUnpack
    '';
    sourceRoot = "source";

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p "$out/share/autostakkert"
      cp -r ./* "$out/share/autostakkert/"

      mkdir -p "$out/bin"
      cat > "$out/bin/autostakkert" <<'EOF'
      #!/bin/sh
      # Isolated Wine prefix; created automatically by wine on first launch.
      export WINEPREFIX="''${XDG_DATA_HOME:-$HOME/.local/share}/autostakkert/wineprefix"
      export WINEARCH=win64
      # Don't nag to install Mono/Gecko; AutoStakkert needs neither.
      export WINEDLLOVERRIDES="mscoree=;mshtml="
      appdir="$WINEPREFIX/drive_c/AutoStakkert"
      mkdir -p "$appdir"
      # Refresh program files from the (read-only) store into the writable prefix.
      cp -f "@sharedir@"/* "$appdir/" 2>/dev/null || true
      chmod -R u+w "$appdir"
      exec wine "$appdir/AutoStakkert.exe" "$@"
      EOF
      substituteInPlace "$out/bin/autostakkert" \
        --replace '@sharedir@' "$out/share/autostakkert"
      chmod +x "$out/bin/autostakkert"
      wrapProgram "$out/bin/autostakkert" \
        --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.wineWowPackages.stable ]}

      # Best-effort icon extraction from the PE resources for the app menu entry.
      mkdir -p "$out/share/pixmaps"
      ( cd "$TMPDIR" \
        && wrestool -x -t 14 "$out/share/autostakkert/AutoStakkert.exe" > as.ico 2>/dev/null \
        && icotool -x as.ico 2>/dev/null \
        && biggest=$(ls -S as*.png 2>/dev/null | head -1) \
        && [ -n "$biggest" ] \
        && cp "$biggest" "$out/share/pixmaps/autostakkert.png" ) || true

      mkdir -p "$out/share/applications"
      cat > "$out/share/applications/autostakkert.desktop" <<'EOF'
      [Desktop Entry]
      Type=Application
      Name=AutoStakkert!4
      GenericName=Lucky Imaging Stacker
      Comment=Stack planetary/lunar/solar image sequences (Windows app via Wine)
      Exec=autostakkert %F
      Icon=autostakkert
      Terminal=false
      Categories=Graphics;Photography;Science;
      EOF

      runHook postInstall
    '';

    meta = with pkgs.lib; {
      description = "Lucky imaging stacking software for planetary astrophotography (Wine)";
      homepage = "https://www.autostakkert.com/";
      license = licenses.unfree;
      platforms = [ "x86_64-linux" ];
      mainProgram = "autostakkert";
    };
  });
in
{
  environment.systemPackages = [ autostakkert ];
}
