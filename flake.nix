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
            quickshell = prev.quickshell.overrideAttrs (old: {
              patches = (old.patches or [ ]) ++ [
                (builtins.toFile "quickshell-default-channel-map.patch" ''
                  diff --git a/src/services/pipewire/node.cpp b/src/services/pipewire/node.cpp
                  --- a/src/services/pipewire/node.cpp
                  +++ b/src/services/pipewire/node.cpp
                  @@ -541,6 +541,44 @@ PwVolumeProps PwVolumeProps::parseSpaPod(const spa_pod* param) {
                  		}
                  	}

                  +	if (props.channels.isEmpty()) {
                  +		// pw-pulse may omit SPA_PROP_channelMap. Match PipeWire's default
                  +		// layouts so volume and channel lists remain aligned.
                  +		using C = PwAudioChannel;
                  +		switch (props.volumes.length()) {
                  +		case 1: props.channels = {C::Mono}; break;
                  +		case 2: props.channels = {C::FrontLeft, C::FrontRight}; break;
                  +		case 3: props.channels = {C::FrontLeft, C::FrontRight, C::LowFrequencyEffects}; break;
                  +		case 4: props.channels = {C::FrontLeft, C::FrontRight, C::RearLeft, C::RearRight}; break;
                  +		case 5:
                  +			props.channels = {C::FrontLeft, C::FrontRight, C::FrontCenter, C::SideLeft, C::SideRight};
                  +			break;
                  +		case 6:
                  +			props.channels = {
                  +				C::FrontLeft, C::FrontRight, C::FrontCenter,
                  +				C::LowFrequencyEffects,
                  +				C::SideLeft, C::SideRight
                  +			};
                  +			break;
                  +		case 7:
                  +			props.channels = {
                  +				C::FrontLeft, C::FrontRight, C::FrontCenter,
                  +				C::RearLeft, C::RearRight,
                  +				C::SideLeft, C::SideRight
                  +			};
                  +			break;
                  +		case 8:
                  +			props.channels = {
                  +				C::FrontLeft, C::FrontRight, C::FrontCenter,
                  +				C::LowFrequencyEffects,
                  +				C::RearLeft, C::RearRight,
                  +				C::SideLeft, C::SideRight
                  +			};
                  +			break;
                  +		default: break;
                  +		}
                  +	}
                  +
                  	if (muteProp) {
                  		spa_pod_get_bool(&muteProp->value, &props.mute);
                  	}
                '')
              ];
            });
            diutalia-shell = final.callPackage ./nix/package.nix {
              inherit version;
            };
          })
        ];
      };

      devShells = eachSystem (system: {
        default = pkgsFor.${system}.callPackage ./nix/shell.nix {
          quickshell = pkgsFor.${system}.quickshell;
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
