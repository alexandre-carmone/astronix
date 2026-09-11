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

  outputs = { self, nixpkgs, home-manager, catppuccin, ... }@inputs:
  let
    # Builds the dev laptop for a given light/dark theme. The `theme` arg flows
    # through specialArgs to the theme preset (see modules/theme.nix).
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
      # The rig has no darkman/dconf light-dark switching, but modules/home.nix
      # still needs a `theme` to pick a Catppuccin flavor: pin it to the latte
      # this host has always used.
      specialArgs = { inherit inputs; theme = "light"; };
      modules = [
        ./hosts/astronix/configuration.nix
        home-manager.nixosModules.home-manager
        catppuccin.nixosModules.catppuccin
        inputs.rekos-web.nixosModules.default
      ];
    };

    # Two prebuilt variants of the dev laptop that differ only by the light/dark
    # `theme` arg (Catppuccin flavor + GNOME color-scheme + wallpaper). darkman
    # activates the sibling one at sunrise/sunset via `nixos-rebuild switch`.
    nixosConfigurations.dev = mkDev "light";
    nixosConfigurations.dev-dark = mkDev "dark";
  };
}
