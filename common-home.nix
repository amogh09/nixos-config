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
      lualine-nvim
      pear-tree # Automatic pairing of brackets
      vim-gitgutter # For git
      vim-surround # Surround text with stuff
      tokyonight-nvim # Theme
      neon # Theme
      sonokai # Theme
      nord-nvim # Theme
      dracula-nvim # Theme
      onedark-nvim # Theme
      catppuccin-nvim # Theme
      kanagawa-nvim # Theme
      rose-pine # Theme
      nightfox-nvim # Theme
      editorconfig-vim # editorconfig
      vim-obsession # For tracking vim sessions
      vim-commentary # For commenting code
      vim-devicons # icons!!
      taboo-vim # Tab management
      telescope-nvim
      telescope-fzf-native-nvim
      vim-test
      neoscroll-nvim
      nvim-treesitter-textobjects
      promise-async
    ];
  };

  xdg.configFile."nvim".source = ./config/neovim;

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "Amogh Rathore";
        email = "amoghdroid09@gmail.com";
      };
    };
    ignores = [ ".envrc" ".direnv/" "Session.vim" ];
  };

  programs.zsh = {
    enable = true;
    initContent =
      ''
        # Dynamic colored prompt
        setopt PROMPT_SUBST
        PS1='%(?.%F{#98fb98}.%F{#ff6b6b})❱%f '

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
        insert_final_newline = true;
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
    typescript-language-server
  ];
}
