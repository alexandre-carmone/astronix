# INA VPN in one command: `inavpn`. It runs the Keycloak SAML login, answers the
# inWebo 2FA with a code from tb-otp, then hands the cookie to openconnect.
# Imported only by hosts/dev. Source and the whole story are in
# ./ina-vpn-auto/tb-otp (README.md).
#
# One-time setup, as alexandre:
#   secret-tool store --label='INA LDAP' ldap password   # the INA password
#   tb-otp enroll --code <activation code>               # a NEW token, from INA selfcare
#   tb-otp set-pin                                       # its PIN, into the keyring
# and put the INA username in ~/.config/ina-vpn.env:
#   echo 'INA_LOGIN=<sso user>' > ~/.config/ina-vpn.env
#
# Then `inavpn` connects in the foreground; Ctrl-C disconnects. Extra arguments
# go to openconnect, e.g. `inavpn --background`.
{ lib, pkgs, ... }:

let
  # TrustBuilder Authenticator 6. tb-otp drives the inWebo library inside it.
  # That library is proprietary and not on npm, so the build lifts it out of
  # the AppImage rather than this repo carrying it. The URL is unversioned: when
  # TrustBuilder ships a new build the hash breaks; refetch it with
  # `nix store prefetch-file <url>`.
  authenticator = pkgs.appimageTools.extract {
    pname = "trustbuilder";
    version = "6.38.0.5319";
    src = pkgs.fetchurl {
      url = "https://download.trustbuilder.com/wp-content/uploads/Authenticator6-Linux.AppImage";
      hash = "sha256-4FeW6N3PByr8owPrAikxUQtZ3emubmToEsutjMxYTHM=";
    };
  };

  tb-otp = pkgs.stdenv.mkDerivation {
    pname = "tb-otp";
    version = "1.0.0";
    src = ./ina-vpn-auto/tb-otp;

    nativeBuildInputs = [ pkgs.nodejs pkgs.makeWrapper ];

    # extract-vendor.sh fills vendor/ from the asar, then checks it loads.
    buildPhase = ''
      runHook preBuild
      patchShebangs scripts
      TB_ASAR=${authenticator}/resources/app.asar ./scripts/extract-vendor.sh
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/libexec/tb-otp
      cp -r src vendor package.json $out/libexec/tb-otp/
      ln -s vendor $out/libexec/tb-otp/node_modules
      makeWrapper ${lib.getExe pkgs.nodejs} $out/bin/tb-otp \
        --add-flags $out/libexec/tb-otp/src/cli.js \
        --prefix PATH : ${lib.makeBinPath [ pkgs.libsecret ]}
      runHook postInstall
    '';

    meta = {
      description = "Headless OTP generator for TrustBuilder / inWebo Authenticator 6";
      license = lib.licenses.unfree; # the vendored inWebo code
      mainProgram = "tb-otp";
    };
  };

  # --prefix, not --set: sudo has to come from /run/wrappers on the system PATH.
  inavpn = pkgs.runCommand "inavpn" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
    meta.mainProgram = "inavpn";
  } ''
    install -Dm755 ${./ina-vpn-auto/tb-otp/bin/ina-vpn} $out/libexec/inavpn
    patchShebangs $out/libexec/inavpn
    makeWrapper $out/libexec/inavpn $out/bin/inavpn \
      --prefix PATH : ${lib.makeBinPath (with pkgs; [
        coreutils
        curl
        gnugrep
        gnused
        hostname-debian
        libsecret
        openconnect
        tb-otp
      ])}
  '';
in
{
  environment.systemPackages = [
    inavpn
    tb-otp # enroll, set-pin, status
  ];
}
