{ pkgs, ... }:

# No keyring. Passwords live in Bitwarden.
# The hosts couldn't unlock one anyway. `dev` logs in by fingerprint and
# `astronix` logs in automatically. So PAM never gets a password to pass to
# gnome-keyring or kwallet.
# Apps that find a keyring would ask to unlock it at every launch.
# So the apps below use a local store instead.
{
  environment.systemPackages = [
    # Chromium's OSCrypt keeps the profile encryption key in gnome-libsecret
    # or kwallet. That key covers cookies and tokens, not just passwords.
    # So turning off saved passwords is not enough.
    # `basic` keeps the key in a file inside the profile.
    # The flag is built into the package, so .desktop launchers get it too.
    (pkgs.brave.override { commandLineArgs = "--password-store=basic"; })
  ];

  # KWallet off for KDE: Plasma on astronix and the KF6 libs kstars uses.
  # With no wallet, they skip it instead of asking for a password.
  # `First Use=false` also hides the "create a new wallet" wizard.
  home-manager.users.alexandre.xdg.configFile."kwalletrc".text = ''
    [Wallet]
    Enabled=false
    First Use=false
  '';
}
