{
  pkgs,
  ...
}:

let
  userData = import ../../common/data/users.nix;
in

{
  environment.systemPackages = [
    pkgs.delta
    pkgs.gitFull
    pkgs.git-auto-fixup
    pkgs.git-auto-squash
    pkgs.git-part-pick
  ];

  environment.etc = {
    "gitconfig".text = ''
      [user]
        name = ${userData.jtojnar.name}
        email = ${userData.jtojnar.email}

      [push]
        default = current
        followTags = true

      [pull]
        ff = only

      [core]
        eol = lf
        autocrlf = false
        pager = delta
        # allow using markdown headings in commit messages
        commentChar = ";"

      [interactive]
        diffFilter = delta --color-only

      [delta]
        navigate = true
        dark = true

      [merge]
        conflictStyle = zdiff3

      [sendemail]
        smtpEncryption = tls
        smtpServer = smtp.gmail.com
        smtpUser = ${userData.jtojnar.email}
        smtpServerPort = 587

      [credential]
        helper = libsecret
    '';
  };
}
