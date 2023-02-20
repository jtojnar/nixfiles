# mala-zahradka-pro-radost.cz

This is the implementation of the operational part of <https://mala-zahradka-pro-radost.cz/> static site.

User pushes changes to the [primary repo for the site on Gitea](https://code.ogion.cz/tojnar.cz/zahradka). The allotted directory `/var/www/mala-zahradka-pro-radost.cz/www` contains a secondary copy of the repo and a `current` symlink pointing to the latest secondary directory. The nginx virtual host then serves the contents of the `public` directory inside the `current`.

Each time a commit is pushed to the primary repo, a *post-receive* hook runs a oneshot systemd service that duplicates the `current` repo, pulls in changes from the primary, runs the `site build` command and, if successful, points the `current` symlink to the new repo. Gitea will be informed about the status and build log will be stored publicly in the `logs` directory.
