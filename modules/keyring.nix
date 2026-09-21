{ pkgs, ... }:

# No keyring, on either host. Passwords live in Bitwarden, and neither host
# could unlock one anyway: `dev` logs in by fingerprint and `astronix`
# autologins, so PAM never sees a password to hand to gnome-keyring or kwallet.
# Apps that find a keyring backend would then ask to unlock it at every launch,
# so the ones below are pointed at a local store instead.
{
  environment.systemPackages = [
    # Chromium's OSCrypt picks up gnome-libsecret or kwallet for the profile
    # encryption key, which covers cookies and tokens, not just saved
    # passwords, so not saving passwords isn't enough to keep it quiet.
    # `basic` keeps that key in a file inside the profile. Baked into the
    # package, so the .desktop launchers get it too.
    (pkgs.brave.override { commandLineArgs = "--password-store=basic"; })
  ];

  # KWallet off for the KDE side: Plasma on astronix and the KF6 bits kstars
  # pulls in. With no wallet they skip it instead of asking for its password.
  # `First Use=false` also hides the "create a new wallet" wizard.
  home-manager.users.alexandre.xdg.configFile."kwalletrc".text = ''
    [Wallet]
    Enabled=false
    First Use=false
  '';
}
