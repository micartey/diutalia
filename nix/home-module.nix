{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.diutalia-shell;
  jsonFormat = pkgs.formats.json { };
  tomlFormat = pkgs.formats.toml { };

  generateJson =
    name: value:
    if lib.isString value then
      pkgs.writeText "diutalia-${name}.json" value
    else if builtins.isPath value || lib.isStorePath value then
      value
    else
      jsonFormat.generate "diutalia-${name}.json" value;
in
{
  options.programs.diutalia-shell = {
    enable = lib.mkEnableOption "Diutalia shell configuration";

    systemd.enable = lib.mkEnableOption "Diutalia shell systemd integration";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      description = "The diutalia-shell package to use";
    };

    settings = lib.mkOption {
      type =
        with lib.types;
        oneOf [
          jsonFormat.type
          str
          path
        ];
      default = { };
      example = lib.literalExpression ''
        {
          bar = {
            position = "bottom";
            floating = true;
            backgroundOpacity = 0.95;
          };
          general = {
            animationSpeed = 1.5;
            radiusRatio = 1.2;
          };
          colorSchemes = {
            darkMode = true;
            useWallpaperColors = true;
          };
        }
      '';
      description = ''
        Diutalia shell configuration settings as an attribute set, string
        or filepath, to be written to ~/.config/diutalia/settings.json.
      '';
    };

    colors = lib.mkOption {
      type =
        with lib.types;
        oneOf [
          jsonFormat.type
          str
          path
        ];
      default = { };
      example = lib.literalExpression ''
         {
           mError = "#dddddd";
           mOnError = "#111111";
           mOnPrimary = "#111111";
           mOnSecondary = "#111111";
           mOnSurface = "#828282";
           mOnSurfaceVariant = "#5d5d5d";
           mOnTertiary = "#111111";
           mOutline = "#3c3c3c";
           mPrimary = "#aaaaaa";
           mSecondary = "#a7a7a7";
           mShadow = "#000000";
           mSurface = "#111111";
           mSurfaceVariant = "#191919";
           mTertiary = "#cccccc";
        }
      '';
      description = ''
        Diutalia shell color configuration as an attribute set, string
        or filepath, to be written to ~/.config/diutalia/colors.json.
      '';
    };

    user-templates = lib.mkOption {
      default = { };
      type =
        with lib.types;
        oneOf [
          tomlFormat.type
          str
          path
        ];
      example = lib.literalExpression ''
        {
          templates = {
            neovim = {
              input_path = "~/.config/diutalia/templates/template.lua";
              output_path = "~/.config/nvim/generated.lua";
              post_hook = "pkill -SIGUSR1 nvim";
            };
          };
        }
      '';
      description = ''
        Template definitions for Diutalia, to be written to ~/.config/diutalia/user-templates.toml.

        This option accepts:
        - a Nix attrset (converted to TOML automatically)
        - a string containing raw TOML
        - a path to an existing TOML file
      '';
    };

    plugins = lib.mkOption {
      type =
        with lib.types;
        oneOf [
          jsonFormat.type
          str
          path
        ];
      default = { };
      example = lib.literalExpression ''
        {
          states = {
            catwalk = {
              enabled = true;
            };
          };
          version = 2;
        }
      '';
      description = ''
        Bundled Diutalia plugin state as an attribute set, string or filepath,
        to be written to ~/.config/diutalia/plugins.json.
      '';
    };

    pluginSettings = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          jsonFormat.type
          str
          path
        ]);
      default = { };
      example = lib.literalExpression ''
        {
          catwalk = {
            minimumThreshold = 25;
            hideBackground = true;
          };
        }
      '';
      description = ''
        Each plugin’s settings as an attribute set, string
        or filepath, to be written to ~/.config/diutalia/plugins/plugin-name/settings.json.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.diutalia-shell = lib.mkIf cfg.systemd.enable {
      warnings = [
        ''
          Running diutalia-shell as a systemd service has been deprecated!
          See https://docs.noctalia.dev/getting-started/nixos/#running-the-shell for details.
        ''
      ];
      Unit = {
        Description = "Diutalia Shell - Wayland desktop shell";
        Documentation = "https://docs.noctalia.dev";
        PartOf = [ config.wayland.systemd.target ];
        After = [ config.wayland.systemd.target ];
        X-Restart-Triggers =
          lib.optional (cfg.settings != { }) "${config.xdg.configFile."diutalia/settings.json".source}"
          ++ lib.optional (cfg.colors != { }) "${config.xdg.configFile."diutalia/colors.json".source}"
          ++ lib.optional (cfg.plugins != { }) "${config.xdg.configFile."diutalia/plugins.json".source}"
          ++ lib.optional (
            cfg.user-templates != { }
          ) "${config.xdg.configFile."diutalia/user-templates.toml".source}"
          ++ lib.mapAttrsToList (
            name: _: "${config.xdg.configFile."diutalia/plugins/${name}/settings.json".source}"
          ) cfg.pluginSettings;
      };

      Service = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
      };

      Install.WantedBy = [ config.wayland.systemd.target ];
    };

    home.packages = lib.optional (cfg.package != null) cfg.package;

    xdg.configFile = {
      "diutalia/settings.json" = lib.mkIf (cfg.settings != { }) {
        source = generateJson "settings" cfg.settings;
      };
      "diutalia/colors.json" = lib.mkIf (cfg.colors != { }) {
        source = generateJson "colors" cfg.colors;
      };
      "diutalia/plugins.json" = lib.mkIf (cfg.plugins != { }) {
        source = generateJson "plugins" cfg.plugins;
      };
      "diutalia/user-templates.toml" = lib.mkIf (cfg.user-templates != { }) {
        source =
          if lib.isString cfg.user-templates then
            pkgs.writeText "diutalia-user-templates.toml" cfg.user-templates
          else if builtins.isPath cfg.user-templates || lib.isStorePath cfg.user-templates then
            cfg.user-templates
          else
            tomlFormat.generate "diutalia-user-templates.toml" cfg.user-templates;
      };
    }
    // lib.mapAttrs' (
      name: value:
      lib.nameValuePair "diutalia/plugins/${name}/settings.json" {
        source = generateJson "${name}-settings" value;
      }
    ) cfg.pluginSettings;

    assertions = [
      {
        assertion = !cfg.systemd.enable || cfg.package != null;
        message = "diutalia-shell: The package option must not be null when systemd service is enabled.";
      }
    ];
  };
}
