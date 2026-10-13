{ ... }:

# Docker daemon and CLI.
# The "docker" group gives access to the daemon socket without sudo.
{
  virtualisation.docker.enable = true;

  users.users.alexandre.extraGroups = [ "docker" ];
}
