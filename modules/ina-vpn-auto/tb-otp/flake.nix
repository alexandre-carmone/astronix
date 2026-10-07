{
  description = "Headless OTP generator for TrustBuilder / inWebo Authenticator 6";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f:
        nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        tb-otp = pkgs.stdenv.mkDerivation {
          pname = "tb-otp";
          version = "1.0.0";
          src = ./.;

          nativeBuildInputs = [ pkgs.makeWrapper ];
          dontConfigure = true;
          dontBuild = true;

          # vendor/ holds neon-lib-js + iw-commons-js and their deps, lifted verbatim from
          # the Authenticator 6 asar. They are on a private registry, so they are committed
          # here rather than fetched. node_modules is a symlink onto vendor.
          installPhase = ''
            runHook preInstall
            if [ ! -d vendor ]; then
              echo "vendor/ is missing from the flake source."
              echo "Run ./scripts/extract-vendor.sh, then 'git add -f vendor' for a nix build."
              exit 1
            fi
            mkdir -p $out/libexec/tb-otp
            cp -r src vendor package.json $out/libexec/tb-otp/
            ln -s vendor $out/libexec/tb-otp/node_modules
            makeWrapper ${pkgs.nodejs}/bin/node $out/bin/tb-otp \
              --add-flags $out/libexec/tb-otp/src/cli.js
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "Headless OTP generator for TrustBuilder / inWebo Authenticator 6";
            platforms = platforms.linux;
            mainProgram = "tb-otp";
          };
        };
        default = tb-otp;
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [ pkgs.nodejs ];
          shellHook = ''
            echo "tb-otp devshell -- node $(node --version)"
            echo "  node src/cli.js status"
          '';
        };
      });
    };
}
