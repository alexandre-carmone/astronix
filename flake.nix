{
  description = "Nix config for an astrophoto computer";

  inputs = {
    nixpkgs.url = "github:alexandre-carmone/nixpkgs/a4caed96e39d0a66d9358029e6951829fe088d33";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rekos-web = {
      url = "github:alexandre-carmone/ekos-web-rust";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix/release-26.05";
  };

  outputs = { self, nixpkgs, home-manager, catppuccin, ... }@inputs:
  let
    # Builds the dev laptop for one theme. `theme` reaches the preset in
    # modules/theme.nix through specialArgs.
    mkDev = theme: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs theme; };
      modules = [
        ./hosts/dev/configuration.nix
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
        inputs.rekos-web.nixosModules.default
      ];
    };

    # The same laptop in light and dark: Catppuccin flavor, GNOME color-scheme
    # and wallpaper. darkman rebuilds into the other at sunrise/sunset.
    nixosConfigurations.dev = mkDev "light";
    nixosConfigurations.dev-dark = mkDev "dark";
  };
}
