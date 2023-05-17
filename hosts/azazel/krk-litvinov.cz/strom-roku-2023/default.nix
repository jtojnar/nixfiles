{ config, myLib, pkgs, ... }:
let
  inherit (myLib) mkVirtualHost;

  vhost = config.services.nginx.virtualHosts."strom-roku-2023.krk-litvinov.cz";
  user = config.users.users.strom-roku-2023.name;
  group = config.users.groups.strom-roku-2023.name;
in {
  age.secrets = {
    "gitea-token-jtojnar-strom-roku-2023".file = ../../../../secrets/gitea-token-jtojnar.age;
  };

  services = {
    nginx = {
      enable = true;

      virtualHosts = {
        "strom-roku-2023.krk-litvinov.cz" = mkVirtualHost {
          acme = true;
          path = "krk-litvinov.cz/strom-roku-2023";
          config = ''
            location / {
              root ${vhost.root}/current/public;
            }
            location /logs {
              root ${vhost.root};
            }
          '';
        };

        "www.strom-roku-2023.krk-litvinov.cz" = mkVirtualHost {
          redirect = "strom-roku-2023.krk-litvinov.cz";
          acme = "strom-roku-2023.krk-litvinov.cz";
        };
      };
    };
  };

  systemd.services."strom-roku-2023-deploy@" = {
    script = ''
      # Deploy log is redirected to be able to link to it.
      logName="logs/$(date --utc "+%Y-%m-%dT%H:%M:%S").log"

      # Required by Nix
      mkdir -p .cache
      export XDG_CACHE_HOME="$PWD/.cache"

      ${pkgs.deploy-pages}/bin/deploy-pages \
        "--site-url=https://strom-roku-2023.krk-litvinov.cz/" \
        "--token-path=$CREDENTIALS_DIRECTORY/token" \
        "--owner=tojnar.cz" \
        "--repo=strom-roku-2023.krk-litvinov.cz" \
        "--commit-sha=$1" \
        "--log-url=https://strom-roku-2023.krk-litvinov.cz/$logName" \
        "--build-command=nix build --accept-flake-config .#{default,roots,vips} --out-link ../result && nix shell --accept-flake-config .#{default,vips} -c site build" \
          2>&1 | tee "$logName"
    '';
    # Pass the instance argument.
    scriptArgs = "%i";
    serviceConfig = {
      Type = "oneshot";
      LoadCredential = [
        "token:${config.age.secrets."gitea-token-jtojnar-strom-roku-2023".path}"
      ];
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
            && (action.lookup("unit") || {match() { return false;}}).match(/^strom-roku-2023-deploy@.+\.service$/)
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
                systemctl start "strom-roku-2023-deploy@$newrev.service" --no-block
            else
                echo "Not running deploy for non-main branch."
            fi
        done
      '';
    in
    [
      "L+ ${config.services.gitea.repositoryRoot}/tojnar.cz/strom-roku-2023.krk-litvinov.cz.git/hooks/post-receive.d/deploy-pages - - - - ${postReceiveHook}"
      "d ${vhost.root} 0755 ${user} ${group} -"
      "D ${vhost.root}/logs 0755 ${user} ${group} -"
    ];
}
