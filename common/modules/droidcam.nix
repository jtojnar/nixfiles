{ config, lib, pkgs, ... }:

let
  inherit (lib) mkEnableOption;

  v4l2loopback-dc = pkgs.v4l2loopback-dc.override {
    inherit (config.boot.kernelPackages) kernel;
  };

  cfg = config.programs.droidcam;
in

{
  options = {
    programs.droidcam = {
      enable = mkEnableOption "droidcam program and associated kernel module";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.extraModulePackages = [
      v4l2loopback-dc
    ];

    boot.kernelModules = [
      "v4l2loopback-dc"
    ];

    environment.systemPackages = [
      pkgs.droidcam
    ];
  };
}
