{ pkgs, ... }:

# Secret-Service (keyring) opt-out, shared by both hosts. Passwords live in
# Bitwarden, and neither host can unlock a keyring at session start anyway:
# `dev` logs in with the fingerprint reader and `astronix` autologins, so PAM
# never sees a password to hand to gnome-keyring/kwallet. Anything that
# autodetects a keyring backend therefore pops an unlock (or "create a wallet")
# dialog on every launch; the apps below are pointed at a local store instead.
{
  environment.systemPackages = [
    # Chromium's OSCrypt autodetects gnome-libsecret/kwallet and uses it for the
    # profile encryption key (cookies and tokens, not just saved passwords), so
    # simply not saving passwords isn't enough to keep it quiet. `basic` keeps
    # that key in an obfuscated file inside the profile. Baked into the package
    # (makeWrapper --add-flags) so the .desktop launchers pick it up too.
    (pkgs.brave.override { commandLineArgs = "--password-store=basic"; })
  ];

  # KWallet off for the KDE side: Plasma on astronix, plus the KF6 bits kstars
  # pulls in (KIO http auth, KNewStuff catalog downloads). With no wallet those
  # skip it instead of asking for a wallet password. `First Use=false` also
  # suppresses the "create a new wallet" wizard.
  home-manager.users.alexandre.xdg.configFile."kwalletrc".text = ''
    [Wallet]
    Enabled=false
    First Use=false
  '';
}
