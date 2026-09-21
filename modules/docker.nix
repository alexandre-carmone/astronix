{ ... }:

# Docker daemon and CLI. The "docker" group lets the user reach the daemon
# socket without sudo.
{
  virtualisation.docker.enable = true;

  users.users.alexandre.extraGroups = [ "docker" ];
}
