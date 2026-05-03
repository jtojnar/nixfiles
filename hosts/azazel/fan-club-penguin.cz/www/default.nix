{
  config,
  lib,
  myLib,
  ...
}:

let
  inherit (myLib) enablePHP;
in
{
  # TODO: enable acme certificate
  # TODO: move to index.php
  services = {
    caddy = {
      enable = true;

      virtualHosts = {
        "fan-club-penguin.cz" = {
          useACMEHost = "fan-club-penguin.cz";
          extraConfig = ''
            root * /var/www/fan-club-penguin.cz/www

            redir /index.php /

            rewrite /sitemap.xml /sitemap.php
            rewrite /rss.xml /rss.php

            handle /search {
              rewrite * /search.php
            }

            @page_html path_regexp ^/(.+)\.html$
            rewrite @page_html /?section=pages&page={re.page_html.1}

            redir /page/show/* /{http.request.uri.path.2}.html

            handle_path /post/* {
              redir /rss /rss.xml

              @view path_regexp ^/post/([^/]+)$
              rewrite @view /?section=posts&page=view&id={re.view.1}

              @edit path_regexp ^/post/([^/]+)/edit$
              rewrite @edit /?section=admin&page=postedit&id={re.edit.1}

              @show path_regexp ^/post/show/(\d+)$
              redir @show /post/{re.show.1}.html
            }

            rewrite /profile /?section=profile&page=list

            handle_path /profile/* {
              @show path_regexp ^/profile/show/(\d+)$
              redir @show /profile/{re.show.1}.html

              @view path_regexp ^/profile/(\d*)$
              rewrite @view /?section=profile&page=view&id={re.view.1}

              @action path_regexp ^/profile/(\d*)/(givestamps|mail)$
              rewrite @action /?section=profile&page={re.action.2}&id={re.action.1}

              rewrite /profile/me /?section=profile&page=me
            }

            handle_path /user/* {
              @user path_regexp ^/user/(logout|login|edit|register)$
              rewrite @user /?section=user&page={re.user.1}
            }

            rewrite /meeting /?section=meeting&page=list

            handle_path /meeting/* {
              @new path /new
              rewrite @new /?section=meeting&page=new

              @editdel path_regexp ^/meeting/(\d*)/(delete|edit)$
              rewrite @editdel /?section=meeting&page={re.editdel.2}&id={re.editdel.1}
            }

            rewrite /mail /?section=mail&page=list

            handle_path /mail/* {
                @sent path /sent
                rewrite @sent /?section=mail&page=sent

                @view path_regexp ^/mail/(\d*)$
                rewrite @view /?section=mail&page=view&id={re.view.1}

                @reply path_regexp ^/mail/(\d*)/reply$
                rewrite @reply /?section=mail&page=reply&id={re.reply.1}

                @show path_regexp ^/mail/show/(\d+)$
                redir @show /mail/{re.show.1}.html
            }

            rewrite /admin /?section=admin&page=panel

            handle_path /admin/* {
                @simple path_regexp ^/admin/(pagenew|pageedit|postnew|posts|pages|twitter|saturdaystamp|highlight|stats)$
                rewrite @simple /?section=admin&page={re.simple.1}
            }

            ${enablePHP "fcp"}

            file_server
          '';
        };

        "www.fan-club-penguin.cz" = {
          useACMEHost = "fan-club-penguin.cz";
          extraConfig = ''
            redir https://fan-club-penguin.cz{uri} permanent
          '';
        };
      };
    };
  };
}
