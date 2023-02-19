{ config, pkgs, ... }:

let
  common = (import ./common-home.nix) { config = config; pkgs = pkgs; };
in
  common //
  {
    home = common.home // { username = "home"; homeDirectory = "/Users/home"; };
    programs = common.programs // { home-manager = { enable = true; }; };
  }
