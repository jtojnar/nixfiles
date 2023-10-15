{ config, myLib, pkgs, ... }:
let
  inherit (myLib) mkVirtualHost;

  vhost = config.services.nginx.virtualHosts."mala-zahradka-pro-radost.cz";
  user = config.users.users.mzpr.name;
  group = config.users.groups.mzpr.name;
in {
  age.secrets = {
    "gitea-token-jtojnar-mzpr" = {
      owner = user;
      file = ../../../../secrets/gitea-token-jtojnar.age;
    };
  };

  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "mala-zahradka-pro-radost.cz" = mkVirtualHost {
          acme = true;
          path = "mala-zahradka-pro-radost.cz/www";
          config = ''
            location / {
              root ${vhost.root}/current/public;
            }
            location /logs {
              root ${vhost.root};
            }
          '';
        };

        "www.mala-zahradka-pro-radost.cz" = mkVirtualHost {
          redirect = "mala-zahradka-pro-radost.cz";
          acme = "mala-zahradka-pro-radost.cz";
        };
      };
    };
  };

  systemd.services."mala-zahradka-pro-radost-cz-deploy@" = {
    script = ''
      # Deploy log is redirected to be able to link to it.
      logName="logs/$(date --utc "+%Y-%m-%dT%H:%M:%S").log"

      # Required by Nix
      mkdir -p .cache
      export XDG_CACHE_HOME="$PWD/.cache"

      ${pkgs.deploy-pages}/bin/deploy-pages \
        "--site-url=https://mala-zahradka-pro-radost.cz/" \
        "--token-path=${config.age.secrets."gitea-token-jtojnar-mzpr".path}" \
        "--owner=tojnar.cz" \
        "--repo=zahradka" \
        "--commit-sha=$1" \
        "--log-url=https://mala-zahradka-pro-radost.cz/$logName" \
        "--build-command=nix build --accept-flake-config .#{default,roots,vips} --out-link ../result && nix shell --accept-flake-config .#{default,vips} -c site build" \
          2>&1 | tee "$logName"
    '';
    # Pass the instance argument.
    scriptArgs = "%i";
    serviceConfig = {
      Type = "oneshot";
      User = user;
      WorkingDirectory = vhost.root;
    };
  };

  nix = {
    settings = {
      # Allow building the site binary.
      allowed-users = [ user ];
    };
  };

  security.polkit.extraConfig = ''
    // Allow gitea to start the deploy service.
    polkit.addRule(function(action, subject) {
        if (action.id === "org.freedesktop.systemd1.manage-units"
            // TODO: Duktape does not currently support ?. operator.
            && (action.lookup("unit") || {match() { return false;}}).match(/^mala-zahradka-pro-radost-cz-deploy@.+\.service$/)
            && action.lookup("verb") === "start"
            && subject.user === "${config.services.gitea.user}") {
            return polkit.Result.YES;
        }
    });
  '';

  systemd.tmpfiles.rules =
    let
      postReceiveHook = pkgs.writeShellScript "run-deploy" ''
        while read oldrev newrev ref; do
            # When on the main branch.
            if [[ "$ref" == refs/heads/main ]]; then
                # Start the systemd service and pass the commit sha as instance argument.
                systemctl start "mala-zahradka-pro-radost-cz-deploy@$newrev.service" --no-block
            else
                echo "Not running deploy for non-main branch."
            fi
        done
      '';
    in
    [
      "L+ ${config.services.gitea.repositoryRoot}/tojnar.cz/zahradka.git/hooks/post-receive.d/deploy-pages - - - - ${postReceiveHook}"
      "d ${vhost.root} 0755 ${user} ${group} -"
      "D ${vhost.root}/logs 0755 ${user} ${group} -"
    ];
}
