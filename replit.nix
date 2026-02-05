{ pkgs }: {
  deps = [
    # Python and core dependencies
    pkgs.python311Full
    pkgs.python311Packages.pip
    pkgs.python311Packages.setuptools
    pkgs.python311Packages.wheel
    
    # Development tools
    pkgs.git
    pkgs.openssh
    pkgs.curl
    pkgs.wget
    
    # Python language server for IDE support
    pkgs.python311Packages.python-lsp-server
    
    # Database clients (for PostgreSQL, Redis)
    pkgs.postgresql
    pkgs.redis
    
    # Additional utilities
    pkgs.vim
    pkgs.nano
    pkgs.htop
    pkgs.tree
  ];
  
  env = {
    PYTHONBIN = "${pkgs.python311Full}/bin/python3.11";
    LANG = "en_US.UTF-8";
    PYTHONPATH = "$REPL_HOME:$PYTHONPATH";
    LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
  };
}
