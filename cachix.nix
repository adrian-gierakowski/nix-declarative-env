# From https://cachix.org/api/v1/install
{ system ? builtins.currentSystem
, onlyFromSource ? false
}:

let
  mkFakeDerivation = attrs: outputs:
    let
        outputNames = builtins.attrNames outputs;
        common = attrs // outputsSet //
            { type = "derivation";
            outputs = outputNames;
            # TODO: this has name/value pairs
            all = outputsList;
            };
        outputToAttrListElement = outputName:
            { name = outputName;
              value = common // {
                inherit outputName;
                outPath = builtins.storePath (builtins.getAttr outputName outputs);
                # TODO: we lie here so that Nix won't build it
                drvPath = builtins.storePath (builtins.getAttr outputName outputs);
              };
            };
        outputsList = map outputToAttrListElement outputNames;
        outputsSet = builtins.listToAttrs outputsList;
    in outputsSet;
  packages = {
    x86_64-linux.cachix =
  (mkFakeDerivation
    { name = "cachix-0.3.8";
      system = "x86_64-linux";
    }
    { out = "/nix/store/spznih45c56kfwygx8qyq1skd1rs4zv1-cachix-0.3.8";
    }).out;

  x86_64-darwin.cachix =
  (mkFakeDerivation
    { name = "cachix-0.3.8";
      system = "x86_64-darwin";
    }
    { out = "/nix/store/4r9q0fkhm0g5hbzn6lc6acf5rdyrz18q-cachix-0.3.8";
    }).out;

  };
in if builtins.hasAttr system packages && (!onlyFromSource)
   then packages.${system}
   else import (fetchTarball "https://github.com/NixOS/nixpkgs/tarball/fa29c1002d1cd82eee612e7db8da0acd2f3b8937") { inherit system; }
