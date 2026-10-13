# INA proxy, on only on the INA wired network. Off everywhere else.
# Imported only by hosts/dev.
#
# The wired network is detected by its DHCP domain: priv.ina.
# A NetworkManager script writes on/off to /run/ina-proxy/state.
# It also sets the proxy for nix-daemon.
# zsh and GNOME read that file.
{ lib, pkgs, ... }:

let
  proxy = "http://firewall.ina.fr:81";
  noProxy = "localhost,127.0.0.1,::1,.ina.fr,.priv.ina,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16";
  inaDomain = "priv.ina";
  state = "/run/ina-proxy/state";
  dropin = "/run/systemd/system/nix-daemon.service.d/ina-proxy.conf";

  # Runs on every network event. $1 is the interface, $2 the action.
  dispatch = pkgs.writeShellApplication {
    name = "ina-proxy-dispatch";
    runtimeInputs = with pkgs; [ coreutils gnugrep networkmanager systemd util-linux ];
    text = ''
      iface=''${1:-}
      action=''${2:-}

      # On if a connected ethernet has the INA domain.
      # Skip the device going down.
      want=off
      while IFS=: read -r dev type devstate; do
        [[ $type == ethernet && $devstate == connected ]] || continue
        [[ $action == down && $dev == "$iface" ]] && continue
        opts=$(nmcli -t -f DHCP4.OPTION device show "$dev")
        if grep -qE ':domain_name = (.* )?${lib.escapeRegex inaDomain}( |$)' <<<"$opts"; then
          want=on
        fi
      done < <(nmcli -t -f DEVICE,TYPE,STATE device)

      current=$(cat ${state} 2>/dev/null || echo off)
      [[ $want == "$current" ]] && exit 0

      echo "$want" > ${state}
      logger -t ina-proxy "INA wired network: proxy $want"

      if [[ $want == on ]]; then
        mkdir -p "$(dirname ${dropin})"
        cat > ${dropin} <<'EOF'
      [Service]
      Environment="http_proxy=${proxy}" "https_proxy=${proxy}" "HTTP_PROXY=${proxy}" "HTTPS_PROXY=${proxy}"
      Environment="no_proxy=${noProxy}" "NO_PROXY=${noProxy}"
      EOF
      else
        rm -f ${dropin}
      fi
      # Restart nix-daemon only if it runs.
      systemctl daemon-reload
      systemctl --no-block try-restart nix-daemon.service
    '';
  };
in
{
  networking.networkmanager.dispatcherScripts = [
    { type = "basic"; source = lib.getExe dispatch; }
  ];

  # Off at boot.
  systemd.tmpfiles.rules = [
    "d /run/ina-proxy 0755 root root -"
    "f ${state} 0644 root root - off"
  ];

  # zsh updates the proxy at each prompt.
  programs.zsh.interactiveShellInit = ''
    _ina_proxy() {
      if [[ -r ${state} && "$(<${state})" == on ]]; then
        export http_proxy=${proxy} https_proxy=${proxy}
        export HTTP_PROXY=${proxy} HTTPS_PROXY=${proxy}
        export no_proxy=${noProxy} NO_PROXY=${noProxy}
      else
        unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
      fi
    }
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _ina_proxy
    _ina_proxy
  '';

  # GNOME proxy settings. The mode is set by the unit below.
  programs.dconf.profiles.user.databases = [
    {
      lockAll = true;
      settings = {
        "org/gnome/system/proxy".ignore-hosts = [
          "localhost" "127.0.0.0/8" "::1"
          "*.ina.fr" "*.priv.ina"
          "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16"
        ];
        "org/gnome/system/proxy/http" = { host = "firewall.ina.fr"; port = lib.gvariant.mkInt32 81; };
        "org/gnome/system/proxy/https" = { host = "firewall.ina.fr"; port = lib.gvariant.mkInt32 81; };
      };
    }
  ];

  # Sets the GNOME proxy mode at login and when the state changes.
  systemd.user.services.ina-proxy = {
    description = "GNOME proxy mode for the INA wired network";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      if [[ -r ${state} && "$(<${state})" == on ]]; then mode=manual; else mode=none; fi
      ${pkgs.dconf}/bin/dconf write /org/gnome/system/proxy/mode "'$mode'"
    '';
  };
  systemd.user.paths.ina-proxy = {
    wantedBy = [ "default.target" ];
    pathConfig.PathChanged = state;
  };

  # Keep the proxy under sudo, for `just switch`.
  security.sudo.extraConfig = ''
    Defaults env_keep += "http_proxy https_proxy no_proxy HTTP_PROXY HTTPS_PROXY NO_PROXY"
  '';
}
