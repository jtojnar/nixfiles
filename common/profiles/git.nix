{
  pkgs,
  ...
}:

let
  userData = import ../../common/data/users.nix;
in

{
  environment.systemPackages = [
    pkgs.diff-so-fancy
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
        pager = diff-so-fancy | less --tabs=4 -RFX
        # allow using markdown headings in commit messages
        commentChar = ";"

      # colour scheme for diff-so-fancy & co.
      # https://github.com/so-fancy/diff-so-fancy#improved-colors-for-the-highlighted-bits
      [color]
        ui = true
      [color "diff-highlight"]
        oldNormal = red bold
        oldHighlight = red bold 52
        newNormal = green bold
        newHighlight = green bold 22
      [color "diff"]
        meta = 227
        frag = magenta bold
        commit = 227 bold
        old = red bold
        new = green bold
        whitespace = red reverse

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
