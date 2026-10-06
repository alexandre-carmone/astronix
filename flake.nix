{
  description = "Nix config for an astrophoto computer";

  inputs = {
    nixpkgs.url = "github:alexandre-carmone/nixpkgs/3fca3558f542c29369b259d2f709c7a1ed45fb03";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    junos = {
      url = "github:alexandre-carmone/Junos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix/release-26.05";
  };

  outputs = { self, nixpkgs, home-manager, catppuccin, ... }@inputs:
  let
    # Builds a GNOME host for one theme. Both args reach the modules through
    # specialArgs: `theme` picks the preset in modules/theme.nix, and `host`,
    # the flake attribute of the light variant, tells modules/darkman.nix
    # which pair of outputs to rebuild between.
    mkGnomeHost = host: theme: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs theme host; };
      modules = [
        ./hosts/${host}/configuration.nix
        home-manager.nixosModules.home-manager
        catppuccin.nixosModules.catppuccin
      ];
    };
  in
  {
    nixosConfigurations.astronix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      # The rig has no light/dark switching, but modules/home.nix still needs a
      # theme to pick a Catppuccin flavor. Pin it to latte.
      specialArgs = { inherit inputs; theme = "light"; };
      modules = [
        ./hosts/astronix/configuration.nix
        home-manager.nixosModules.home-manager
        catppuccin.nixosModules.catppuccin
        inputs.junos.nixosModules.default
      ];
    };

    # Each GNOME host in light and dark: Catppuccin flavor and GNOME
    # color-scheme. darkman rebuilds into the other at sunrise/sunset.
    nixosConfigurations.dev = mkGnomeHost "dev" "light";
    nixosConfigurations.dev-dark = mkGnomeHost "dev" "dark";

    # The gaming desktop.
    nixosConfigurations.gamix = mkGnomeHost "gamix" "light";
    nixosConfigurations.gamix-dark = mkGnomeHost "gamix" "dark";
  };
}
