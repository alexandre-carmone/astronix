{ ... }:

# Docker engine: installs the daemon (server) and the `docker` CLI (client).
# Adding the user to the "docker" group lets it talk to the daemon socket
# without sudo.
{
  virtualisation.docker.enable = true;

  users.users.alexandre.extraGroups = [ "docker" ];
}
