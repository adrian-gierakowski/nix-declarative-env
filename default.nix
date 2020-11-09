# Based on https://gist.github.com/LnL7/570349866bb69467d0caf5cb175faa74 and https://stackoverflow.com/a/50747830
let
  nixEnvConfigDirPath = ".config/nix/env";
  nixSourcesPath = "${nixEnvConfigDirPath}/nix/sources.nix";
  homeDir = builtins.getEnv "HOME";
  sources = import "${homeDir}/${nixSourcesPath}";
  # Custom version of nix.
  nixGit = builtins.fetchGit {
    name = "nix-git-source";
    url  = "https://github.com/adrian-gierakowski/nix.git";
    ref  = "ag/s3-configurable-timeout";
    rev  = "6f162d8fcf354e513e165ae780f517e86c1a00ca";
  };
  nixSrcTarbals = (import "${nixGit}/release.nix" { nix = nixGit; }).tarball;
  pkgs = import sources.nixpkgs {
    overlays = [
      (self: super: {
        nix = super.nix.overrideAttrs (oldAttrs: {
          src = "${nixSrcTarbals}/tarballs/nix-${nixSrcTarbals.version}.tar.bz2";

          # Theses seem to fail on MacOS due to sandbox path being too long
          checkPhase = "true";
          installCheckPhase = "true";
        });
      })
    ];
  };

  yarn2nixFromSource = (import sources.yarn2nix { inherit pkgs; }).yarn2nix;
  nix = pkgs.nix;

  ensureNixOnPath = ''
    if ! command -v nix &>/dev/null; then
        echo "warning: nix was not found on PATH, add nix to attrset returned by $HOME/${nixEnvConfigDirPath}/default.nix" >&2
        PATH=${nix}/bin:$PATH
    fi
  '';
in {
  inherit nix;
  inherit (import ./cachix.nix { system = builtins.currentSystem; }) cachix;
  cacert = pkgs.cacert;

  nixpkgs-info = pkgs.writeScriptBin "nixpkgs-info" ''
    #!${pkgs.stdenv.shell}
    ${ensureNixOnPath}

    nix eval --json '(builtins.removeAttrs (import $HOME/${nixSourcesPath} ).nixpkgs [ "outPath" ])' | ${pkgs.jq}/bin/jq .
  '';

  nix-rebuild = pkgs.writeScriptBin "nix-rebuild" ''
    #!${pkgs.stdenv.shell}
    ${ensureNixOnPath}

    exec nix-env "$@" --install --remove-all --file $HOME/${nixEnvConfigDirPath}
  '';

  inherit (pkgs)
    niv
    nixfmt
    binutils-unwrapped # readelf
    colordiff
    direnv
    fd
    fswatch
    fzf
    git
    ipcalc
    jq
    lorri
    nix-prefetch-git
    nixpkgs-fmt
    privoxy
    ripgrep
    sops
    terraform
    tinyproxy
    tmux
    watch
    yarn2nix
    yq
    # nix-du
    # dot
  ;

  hub = pkgs.gitAndTools.hub;
  # nix-visualize = import sources.nix-visualize { inherit pkgs; };
  # yarn2nix = yarn2nixFromSource;
  linuxkit-builder = /nix/store/jgq3savsyyrpsxvjlrz41nx09z7r0lch-linuxkit-builder;
}