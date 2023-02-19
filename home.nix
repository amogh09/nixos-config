{ config, pkgs, ... }:

let
  common = (import ./common-home.nix) { config = config; pkgs = pkgs; };
in
  common //
  {
    home = common.home;
      # Uncomment the following and update the values
      # //
      # { username = "amogh";             # Change this to actual username
      #   homeDirectory = "/home/amogh";  # Change this to actual home dir
      # };
    programs = common.programs // { home-manager = { enable = true; }; };
  }
