{
  description = "Nix config for an astrophoto computer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/e3ed29f0e112ed8e47525ba8b7f19ae0762b0824";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    ekos-web-rust.url = "github:alexandre-carmone/ekos-web-rust";
    nvim-config = {
      url = "github:alexandre-carmone/nvim";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.astronix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/astronix/configuration.nix
        home-manager.nixosModules.home-manager
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
