# Based on https://gist.github.com/LnL7/570349866bb69467d0caf5cb175faa74 and https://stackoverflow.com/a/50747830
let
  nixEnvConfigDirPath = ".config/nix/env";
  nixSourcesPath = "${nixEnvConfigDirPath}/nix/sources.nix";
  homeDir = builtins.getEnv "HOME";
  nixpkgs = (import "${homeDir}/${nixSourcesPath}").nixpkgs;

  # Custom version of nix.
  nixGit = builtins.fetchGit {
    name = "nix-git-source";
    url  = "https://github.com/adrian-gierakowski/nix.git";
    ref  = "ag/s3-configurable-timeout";
    rev  = "56e9ac7ba2fab539fd20a9701a85f4108124073e";
  };
  nixSrcTarbals = (import "${nixGit}/release.nix" { nix = nixGit; }).tarball;
  pkgs = import nixpkgs {
    overlays = [
      (self: super: {
        nix = super.nix.overrideAttrs (oldAttrs: {
          src = "${nixSrcTarbals}/tarballs/nix-${nixSrcTarbals.version}.tar.bz2";

          checkPhase = "true";
          installCheckPhase = "true";
        });
      })
    ];
  };
  nix = pkgs.nix;

  ensureNixOnPath = ''
    if ! command -v nix &>/dev/null; then
        echo "warning: nix was not found on PATH, add nix to attrset returned by $HOME/${nixEnvConfigDirPath}/default.nix" >&2
        PATH=${nix}/bin:$PATH
    fi
  '';
in {
  inherit nix;
  cacert = pkgs.cacert;

  nixpkgs-info = pkgs.writeScriptBin "nixpkgs-info" ''
    #!${pkgs.stdenv.shell}
    ${ensureNixOnPath}

    nix eval --json '(builtins.removeAttrs (import $HOME/${nixSourcesPath} ).nixpkgs [ "outPath" ])' | ${pkgs.jq}/bin/jq .
  '';

  nix-rebuild = pkgs.writeScriptBin "nix-rebuild" ''
    #!${pkgs.stdenv.shell}
    ${ensureNixOnPath}

    exec nix-env --install --remove-all --file $HOME/${nixEnvConfigDirPath}
  '';

  inherit (pkgs)
    binutils-unwrapped # readelf
    # cachix
    direnv
    fd
    fzf
    ipcalc
    lorri
    niv
    nix-prefetch-git
    nixfmt
    nixpkgs-fmt
    privoxy
    ripgrep
    sops
    tinyproxy
    yarn2nix-moretea
  ;
  linuxkit-builder = /nix/store/jgq3savsyyrpsxvjlrz41nx09z7r0lch-linuxkit-builder;
}