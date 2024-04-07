{ lib
, pkgs
, config
, ...
}:

let
  inherit (lib) mkOption mkEnableOption mkIf;

  cfg = config.services.pgs;
  defaultUser = "pgs";
in
{
  options.services.pgs = {
    enable = mkEnableOption "whether to enable pgs.";

    package = lib.mkPackageOption pkgs "pgs" { };

    user = lib.mkOption {
      type = lib.types.str;
      default = defaultUser;
      description = lib.mdDoc ''
        User under which the service should run. If this is the default value,
        the user will be created, with the specified group as the primary
        group.
      '';
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = defaultUser;
      description = lib.mdDoc ''
        Group under which the service should run. If this is the default value,
        the group will be created.
      '';
    };

    openFirewall = mkEnableOption "Open ports in the firewall for pgs.";

    environment = mkOption {
      type = with lib.types; attrsOf (nullOr (oneOf [ str path package ]));
      description = lib.mdDoc ''
        all general env
        ```
        DATABASE_URL=postgresql://postgres:secret@postgres:5432/pico?sslmode=disable
        POSTGRES_PASSWORD=secret
        CF_API_TOKEN=secret
        ```

        all PGS_* env
        ```
        PGS_CADDYFILE=./caddy/Caddyfile
        PGS_V4=
        PGS_V6=
        PGS_HTTP_V4=$PGS_V4:80
        PGS_HTTP_V6=[$PGS_V6]:80
        PGS_HTTPS_V4=$PGS_V4:443
        PGS_HTTPS_V6=[$PGS_V6]:443
        PGS_SSH_V4=$PGS_V4:22
        PGS_SSH_V6=[$PGS_V6]:22
        PGS_HOST=
        PGS_SSH_PORT=2222
        PGS_WEB_PORT=3000
        PGS_PROM_PORT=9222
        PGS_DOMAIN=pgs.dev.pico.sh:3005
        PGS_EMAIL=hello@pico.sh
        PGS_SUBDOMAINS=1
        PGS_CUSTOMDOMAINS=1
        PGS_PROTOCOL=http
        PGS_ALLOW_REGISTER=1
        PGS_STORAGE_DIR=.storage
        PGS_DEBUG=1
        ```
      '';
      default = { };
    };
  };

  config = mkIf cfg.enable {
    users = {
      users = lib.optionalAttrs (cfg.user == defaultUser) {
        ${defaultUser} = {
          isSystemUser = true;
          inherit (cfg) group;
        };
      };
      groups = lib.optionalAttrs (cfg.group == defaultUser) {
        ${defaultUser} = { };
      };
    };

    # ===

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts =
        let
          tryGet = attr: lib.optional (builtins.hasAttr attr cfg.environment) (lib.toInt cfg.environment.${attr});
        in
        (tryGet "PGS_SSH_PORT") ++ (tryGet "PGS_WEB_PORT") ++ (tryGet "PGS_PROM_PORT");
    };

    # ===

    systemd.sockets.pgs-ssh = lib.mkIf (cfg.environment ? PGS_SSH_PORT) {
      unitConfig.Description = "pgs SSH socket";
      wantedBy = [ "sockets.target" ];
      listenStreams = [ cfg.environment.PGS_SSH_PORT ];
    };

    systemd.services = {
      pgs-ssh = {
        description = "pgs ssh service";
        wantedBy = [ "multi-user.target" ];
        requires = [ "pgs-ssh.socket" ];

        after = [ "pgs-ssh.socket" "network.target" ] ++
          lib.optional config.services.postgresql.enable "postgresql.service";

        inherit (cfg) environment;

        serviceConfig = {
          ExecStart = lib.getExe' cfg.package "ssh";

          Restart = "on-failure";

          User = cfg.user;
          Group = cfg.group;

          StandardInput = "socket";
          StandardOutput = "journal";

          StateDirectory = "pgs-ssh";
          StateDirectoryMode = "0750";
          RuntimeDirectory = "pgs-ssh";
          RuntimeDirectoryMode = "0750";
          WorkingDirectory = "/var/lib/pgs-ssh";
        };
      };

      pgs-web-init = {
        description = "pgs web init service";
        wantedBy = [ "pgs-web.service" ];

        script = ''
          cp -r ${cfg.package}/pgs .
        '';

        serviceConfig = {
          Type = "oneshot";

          User = cfg.user;
          Group = cfg.group;

          StateDirectory = "pgs-web";
          StateDirectoryMode = "0750";
          RuntimeDirectory = "pgs-web";
          RuntimeDirectoryMode = "0750";
          WorkingDirectory = "/var/lib/pgs-web";
        };
      };
      pgs-web = {
        description = "pgs web service";
        wantedBy = [ "multi-user.target" ];

        after = [ "network.target" "pgs-web-init.service" ] ++
          lib.optional config.services.postgresql.enable "postgresql.service";

        inherit (cfg) environment;

        serviceConfig = {
          ExecStart = lib.getExe' cfg.package "web";

          Restart = "on-failure";

          User = cfg.user;
          Group = cfg.group;

          StateDirectory = "pgs-web";
          StateDirectoryMode = "0750";
          RuntimeDirectory = "pgs-web";
          RuntimeDirectoryMode = "0750";
          WorkingDirectory = "/var/lib/pgs-web";
        };
      };
    };
  };
}

