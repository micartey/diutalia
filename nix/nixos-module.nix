{
  config,
  lib,
  ...
}:
let
  cfg = config.services.diutalia-shell;
in
{
  options.services.diutalia-shell = {
    enable = lib.mkEnableOption "Diutalia shell systemd service";

    package = lib.mkOption {
      type = lib.types.package;
      description = "The diutalia-shell package to use";
    };

    target = lib.mkOption {
      type = lib.types.str;
      default = "graphical-session.target";
      example = "hyprland-session.target";
      description = "The systemd target for the diutalia-shell service.";
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = [
      ''
        Running diutalia-shell as a systemd service has been deprecated!
        See https://docs.noctalia.dev/getting-started/nixos/#running-the-shell for details.
      ''
    ];
    systemd.user.services.diutalia-shell = {
      description = "Diutalia Shell - Wayland desktop shell";
      documentation = [ "https://docs.noctalia.dev" ];
      after = [ cfg.target ];
      partOf = [ cfg.target ];
      wantedBy = [ cfg.target ];
      restartTriggers = [ cfg.package ];

      environment = {
        PATH = lib.mkForce null;
      };

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
      };
    };

    environment.systemPackages = [ cfg.package ];
  };
}
