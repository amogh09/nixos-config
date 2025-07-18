{ config, pkgs, ... }:

{
  home.stateVersion = "22.11";

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  targets.genericLinux.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      gruvbox
      nerdtree

      # LSP
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp_luasnip
      luasnip

      # Treesitter
      (nvim-treesitter.withPlugins (p: [
        p.go
        p.haskell
        p.nix
        p.json
        p.lua
        p.bash
      ]))

      vim-unimpaired # Helpful keybindings
      vim-airline
      pear-tree # Automatic pairing of brackets
      vim-gitgutter # For git
      vim-surround # Surround text with stuff
      tokyonight-nvim # Theme
      neon # Theme
      sonokai # Theme
      editorconfig-vim # editorconfig
      vim-obsession # For tracking vim sessions
      vim-commentary # For commenting code
      vim-devicons # icons!!
      taboo-vim # Tab management
      telescope-nvim
      telescope-fzf-native-nvim
      vim-test

      # Custom QChat plugin from GitHub
      {
        plugin = pkgs.vimUtils.buildVimPlugin {
          pname = "qchat-nvim";
          version = "main";
          src = pkgs.fetchFromGitHub {
            owner = "amogh09";
            repo = "qchat-nvim";
            rev = "main";
            sha256 = "sha256-kY5eXsNNmRPLJKqmnm8F8GLe0S8ZVB0Aog2BeAP6QLM="; # Will be updated on first run
          };
        };
      }
    ];
  };

  xdg.configFile."nvim".source = ./config/neovim;

  programs.git = {
    enable = true;
    userName = "Amogh Rathore";
    userEmail = "amoghdroid09@gmail.com";
    ignores = [ ".envrc" ".direnv/" "Session.vim" ];
  };

  programs.zsh = {
    enable = true;
    initContent =
      ''
        # Prompt
        set_ps1() {
          local exit_status="$?"
          if [[ $exit_status -eq 0 ]]; then
            PS1='%F{#fadfad}%m%f %F{#20ff5e}%{%G❱%}%f '
          else
            PS1='%F{#fadfad}%m%f %F{#ff063e}%{%G❱%}%f '
          fi
        }

        precmd_functions+=(set_ps1)

        autoload -U edit-command-line
        zle -N edit-command-line
        bindkey '^Xe' edit-command-line
      '';
    autosuggestion.enable = true;
    defaultKeymap = "emacs";
    syntaxHighlighting = {
      enable = true;
    };
    historySubstringSearch = {
      enable = true;
    };
    shellAliases = {
      ll = "ls -la";
      gst = "git status";
      ga = "git add";
      gco = "git checkout";
      gfo = "git fetch origin";
      gfu = "git fetch upstream";
      gd = "git diff";
      gdc = "git diff --cached";
      gdca = "git diff --cached";
      gcmsg = "git commit -m";
      glo = "git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
      ggp = "git push origin";
      ggl = "git pull origin";
      gb = "git branch";
    };
  };

  programs.fzf = {
    enable = true;
  };

  editorconfig = {
    enable = true;
    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        trim_trailing_whitespace = true;
        insert_final_newline = false;
        indent_style = "space";
        indent_size = 4;
      };
      "*.{lua,nix}" = {
        indent_size = 2;
      };
      "Makefile" = {
        indent_style = "tab";
        indent_size = 4;
      };
    };
  };

  programs.tmux = {
    enable = true;
    keyMode = "vi";
  };

  home.packages = with pkgs; [
    tree
    bat
    neovim-remote
    ripgrep
    nodePackages_latest.vscode-langservers-extracted
    nodePackages_latest.bash-language-server
    jq
    htop
    curl
    unixtools.netstat
    fd
    lua-language-server
    nixd
    wget
    tmux
    shellcheck
    gnumake
    netcat
    yaml-language-server
  ];
}
