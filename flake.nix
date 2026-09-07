{
  description = "Nix config for an astrophoto computer";

  inputs = {
    nixpkgs.url = "github:alexandre-carmone/nixpkgs/1a2d5a644cfe2711d33a33ba378079bac851991c";
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

  outputs = { self, nixpkgs, home-manager, catppuccin, ... }@inputs: {
    nixosConfigurations.astronix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/astronix/configuration.nix
        home-manager.nixosModules.home-manager
        catppuccin.nixosModules.catppuccin
        inputs.rekos-web.nixosModules.default
      ];
    };

    nixosConfigurations.dev = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/dev/configuration.nix
        home-manager.nixosModules.home-manager
        catppuccin.nixosModules.catppuccin
      ];
    };
  };
}
