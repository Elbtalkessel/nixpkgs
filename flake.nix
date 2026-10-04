{
  description = "A collection of reusable Nix package definitions and overlays.";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nuenv = {
      url = "https://flakehub.com/f/xav-ie/nuenv/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nuenv,
      ...
    }:
    let
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          overlays = [ nuenv.overlays.default ];
        };

      # Packages structure as follows:
      # pkgs/
      #   by-name/
      #     <package-group>/
      #       <package-name>/
      #         default.nix
      # Read child directory function reads a given path (./pkgs/by-name)
      # and returns an absolute paths to each <package-name>/
      rcd =
        p:
        map (v: nixpkgs.lib.path.append p v) (
          builtins.attrNames (
            nixpkgs.lib.filterAttrs (_: val: val == "directory") (builtins.readDir p)
          )
        );
      pp = nixpkgs.lib.flatten (map rcd (rcd ./pkgs/by-name));

      makePackages =
        system:
        let
          pkgs = pkgsFor system;
        in
        builtins.listToAttrs (
          map (p: {
            name = (baseNameOf p);
            value =
              let
                pkg = pkgs.callPackage p { };
              in
              if pkgs.lib.isDerivation pkg then pkg else pkg.preview or pkg.default or pkg.chili or pkg;
          }) pp
        );
    in
    {
      packages = forAllSystems (system: makePackages system);

      overlays.default =
        _: prev:
        let
          inherit (prev.stdenv.hostPlatform) system;
          pkgs = self.packages.${system};
        in
        builtins.listToAttrs (
          map (p: {
            name = (baseNameOf p);
            value = pkgs.${baseNameOf p};
          }) pp
        );
    };
}
