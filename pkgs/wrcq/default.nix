{ pkgs }:

(import ./source { inherit pkgs; }).package.overrideAttrs (atts: {
  passthru = {
    updateScript = ./update.sh;
  };
})
