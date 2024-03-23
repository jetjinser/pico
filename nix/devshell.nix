{ inputs
, ...
}:

{
  imports = [
    inputs.devshell.flakeModule
  ];

  perSystem = { pkgs, lib, inputs', ... }:
    let
      callPackage = pkgs.darwin.apple_sdk_11_0.callPackage or pkgs.callPackage;
    in
    {
      devshells.default = {
        packagesFrom = [
          (callPackage ./_shell.nix {
            inherit (inputs'.gomod2nix.legacyPackages) mkGoEnv gomod2nix;
          })
        ];

        packages = with pkgs; [
          go
          gopls

          postgresql
        ];

        env =
          let
            gen = lib.mapAttrsToList lib.nameValuePair;
          in
          [
            {
              name = "PGHOST";
              eval = "$(PWD)/.tmp";
            }
            {
              name = "DATABASE_URL";
              eval = "postgres:///pico?host=$(PWD)/.tmp";
            }
          ] ++ gen {
            PGS_DEBUG = 1;
            PGS_DOMAIN = "pgs.yeufossa.org";
            PGS_EMAIL = "hello@yeufossa.org";
            PGS_PROTOCOL = "http";
          };

        commands = [
          {
            category = "dev";
            name = "cleandb";
            help = "clean the pico postgres dev database";
            package = pkgs.writeShellApplication {
              name = "cleandb";
              runtimeInputs = [ pkgs.postgresql ];
              text = ''
                rm -r .tmp/picodb
              '';
            };
          }
          {
            category = "dev";
            name = "stopdb";
            help = "Stop db services manually";
            package = pkgs.writeShellApplication {
              name = "stopdb";
              runtimeInputs = [ pkgs.postgresql ];
              text = ''
                pg_ctl -D .tmp/picodb stop
                rm -r .data/
              '';
            };
          }
          {
            category = "dev";
            name = "condb";
            help = "Connect db services via psql";
            package = pkgs.writeShellApplication {
              name = "condb";
              runtimeInputs = [ pkgs.postgresql ];
              text = ''
                psql -d pico
              '';
            };
          }
        ];

        serviceGroups = {
          db = {
            services = {
              postgres.command = lib.getExe (
                pkgs.writeShellApplication {
                  name = "postgres-in-shell-service";

                  runtimeInputs = [ pkgs.postgresql ];

                  text = ''
                    # Create a database with the data stored in the current directory
                    if [[ ! -e ".tmp/picodb" ]]; then
                      initdb -D .tmp/picodb
                      chmod -R 700 .tmp/picodb
                    fi

                    # Start PostgreSQL running as the current user
                    # and with the Unix socket in the current directory
                    pg_ctl -D .tmp/picodb -l .tmp/logfile -o "--unix_socket_directories='$PWD/.tmp/'" start

                    createdb pico
                  '';
                });
            };
          };
        };
      };
    };
}
