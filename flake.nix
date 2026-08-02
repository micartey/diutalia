{
  description = "Diutalia shell - a Wayland desktop shell built with Quickshell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    diutalia-qs = {
      url = "github:diutalia-dev/diutalia-qs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      diutalia-qs,
      ...
    }:
    let
      eachSystem = nixpkgs.lib.genAttrs nixpkgs.lib.platforms.linux;
      pkgsFor = eachSystem (
        system:
        nixpkgs.legacyPackages.${system}.appendOverlays [
          self.overlays.default
        ]
      );

      mkDate =
        longDate:
        nixpkgs.lib.concatStringsSep "-" [
          (builtins.substring 0 4 longDate)
          (builtins.substring 4 2 longDate)
          (builtins.substring 6 2 longDate)
        ];

      version = mkDate (self.lastModifiedDate or "19700101") + "_" + (self.shortRev or "dirty");
    in
    {
      formatter = eachSystem (system: pkgsFor.${system}.nixfmt);

      packages = eachSystem (system: {
        default = pkgsFor.${system}.diutalia-shell;
      });

      overlays = {
        default = nixpkgs.lib.composeManyExtensions [
          diutalia-qs.overlays.default
          (final: prev: {
            diutalia-shell = final.callPackage ./nix/package.nix {
              inherit version;
            };
          })
        ];
      };

      devShells = eachSystem (system: {
        default = pkgsFor.${system}.callPackage ./nix/shell.nix {
          quickshell = diutalia-qs.packages.${system}.default;
        };
      });

      homeModules.default =
        {
          pkgs,
          lib,
          ...
        }:
        {
          imports = [ ./nix/home-module.nix ];
          programs.diutalia-shell.package =
            lib.mkDefault
              self.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };

      nixosModules.default =
        {
          pkgs,
          lib,
          ...
        }:
        {
          imports = [ ./nix/nixos-module.nix ];
          services.diutalia-shell.package =
            lib.mkDefault
              self.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };
    };
}
