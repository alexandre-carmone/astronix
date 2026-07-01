{
  description = "Nix config for an astrophoto computer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/9c17c87fd89099bb81b527f2f101a07a7827a79b";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rekos-web = {
      url = "github:alexandre-carmone/ekos-web-rust";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    kstars-headless = {
      url = "github:alexandre-carmone/kstars-headless";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvim-config = {
      url = "github:alexandre-carmone/nvim";
      flake = false;
    };
    lazyvim = {
      url = "github:pfassina/lazyvim-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.astronix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/astronix/configuration.nix
        home-manager.nixosModules.home-manager
        inputs.rekos-web.nixosModules.default
        inputs.kstars-headless.nixosModules.default
      ];
    };

    nixosConfigurations.dev = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/dev/configuration.nix
        home-manager.nixosModules.home-manager
      ];
    };
  };
}
