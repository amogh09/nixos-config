{ config, pkgs, ... }:

let
  common = (import ./common-home.nix) { config = config; pkgs = pkgs; };
  username = builtins.getEnv "USER";
  homeDir = builtins.getEnv "HOME";
in
  common //
  {
    home = common.home // { username = username; homeDirectory = homeDir; };
    programs = common.programs // { home-manager = { enable = true; }; };
  }
