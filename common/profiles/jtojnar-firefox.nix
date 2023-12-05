{
  pkgs,
  ...
}:

{
  programs.firefox = {
    enable = true;
    package = pkgs.firefox.override (args: {
      cfg = args.cfg or {} // {
        speechSynthesisSupport = true;
      };
    });

    preferences = {
      # Downloading random PDFs from http website is super annoing with this.
      "dom.block_download_insecure" = false;

      # Always use XDG portals for stuff
      "widget.use-xdg-desktop-portal.file-picker" = 1;

      # Enable userChrome.css
      "toolkit.legacyUserProfileCustomizations.stylesheets" = true;

      # Avoid cluttering ~/Downloads for the “Open” action on a file to download.
      "browser.download.start_downloads_in_tmp_dir" = true;

      # Use dark background on about:blank.
      "browser.display.background_color" = "#1C1B22";
      "browser.display.foreground_color" = "#FBFBFE";
    };
  };

  home-manager.users.jtojnar = { lib, ... }: {
    home.file.".mozilla/firefox/f6a1brtw.default/chrome/userChrome.css".text = ''
      @-moz-document url(chrome://browser/content/browser.xul),
      url(chrome://browser/content/browser.xhtml) {
          #main-window[tabsintitlebar="true"]:not([extradragspace="true"]) #TabsToolbar,
          #main-window:not([tabsintitlebar="true"]) #TabsToolbar {
              visibility: collapse !important;
          }
      }
    '';
  };
}
