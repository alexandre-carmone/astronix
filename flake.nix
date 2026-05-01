{
  description = "Nix config for an astrophoto computer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/e3ed29f0e112ed8e47525ba8b7f19ae0762b0824";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rekos-web = {
      url = "git+file:///home/alexandre/PycharmProjects/rekos-web";
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
