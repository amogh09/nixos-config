{ config, pkgs, ... }:

let
  x = (import ./common-home.nix) { config = config; pkgs = pkgs; };
in
  x //
  {
    home = x.home // { username = "home"; homeDirectory = "/Users/home"; };
    programs = x.programs // { home-manager = { enable = true; }; };
  }
