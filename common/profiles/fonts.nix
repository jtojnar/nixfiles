{ pkgs, ... }:

{
  fonts = {
    packages = with pkgs; [
      cantarell-fonts
      caladea # Cambria replacement
      carlito # Calibri replacement
      comic-relief # Comic Sans replacement
      cm_unicode
      crimson
      dejavu_fonts
      fira
      fira-mono
      gentium
      google-fonts
      (input-fonts.override { acceptLicense = true; })
      ipafont
      ipaexfont
      league-of-moveable-type
      libertine
      noto-fonts-color-emoji
      (joypixels.override { acceptLicense = true; })
      liberation_ttf_v2 # Arial, Times New Roman & Courier New replacement
      # libre-baskerville
      libre-bodoni
      libre-caslon
      lmmath
      lmodern
      source-code-pro
      # source-sans-pro
      # source-serif-pro
      ubuntu_font_family
    ];
  };
}
