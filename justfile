# astronix — task runner for this flake.
# `just` alone lists every recipe. Recipes default to the host you are on.

# Flake attribute for the running machine. Override it on any recipe:
# `just switch astronix`.
host := if `hostname` == "astronomix" { "astronix" } else { "dev" }
flake := justfile_directory()

_default:
    @just --list

# Rebuild and activate this host's configuration.
switch target=host:
    sudo nixos-rebuild switch --flake {{flake}}#{{target}}

# Build and make it the next boot's default, without activating now.
boot target=host:
    sudo nixos-rebuild boot --flake {{flake}}#{{target}}

# Activate temporarily — reverts on reboot.
try target=host:
    sudo nixos-rebuild test --flake {{flake}}#{{target}}

# Build without touching the running system; result lands in ./result.
build target=host:
    nixos-rebuild build --flake {{flake}}#{{target}}

# Build this host and list what would change versus the running system.
diff target=host:
    nixos-rebuild build --flake {{flake}}#{{target}}
    nix store diff-closures /run/current-system ./result

# Evaluate every host without building. The cheap "did I break it?" check.
check:
    nix flake check {{flake}}

# Bump every flake input.
update:
    nix flake update --flake {{flake}}

# Bump a single input, e.g. `just update-input nixpkgs`.
update-input input:
    nix flake update {{input}} --flake {{flake}}

# Switch the dev laptop to dark, as darkman does at dusk.
dark:
    sudo nixos-rebuild switch --flake {{flake}}#dev-dark

# Switch the dev laptop back to the light variant.
light:
    sudo nixos-rebuild switch --flake {{flake}}#dev

# List system generations.
generations:
    nixos-rebuild list-generations

# Roll back to the previous generation.
rollback:
    sudo nixos-rebuild switch --rollback

# Drop generations older than DAYS (default 7), system and user, then collect.
gc days="7":
    sudo nix-collect-garbage --delete-older-than {{days}}d
    nix-collect-garbage --delete-older-than {{days}}d

# Free the store of everything unreachable, then optimise it.
prune: (gc "0")
    nix store optimise
