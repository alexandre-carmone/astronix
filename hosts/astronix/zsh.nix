  

{ config, pkgs, ... }:
{
users.users.alexandre.shell = pkgs.zsh;
	environment.shells = with pkgs; [ zsh ];
   programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      edit = "sudo -e";
      update = "sudo nixos-rebuild switch";
    };

    histSize = 10000;
    histFile = "$HOME/.zsh_history";
    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
    ];
  };

programs.zsh.ohMyZsh = {
    enable = true;
    plugins = [ "git" "zsh-interactive-cd" "history-substring-search"];
    theme = "skaro";
  };


}
