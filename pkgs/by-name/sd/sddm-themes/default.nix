{
  stdenvNoCC,
  fetchFromGitHub,
  libsForQt5,
}:
{
  chili = stdenvNoCC.mkDerivation rec {
    pname = "sddm-chili";
    version = "0.1.5";
    dontBuild = true;
    propagatedUserEnvPkgs = [
      libsForQt5.qtgraphicaleffects
      libsForQt5.qtquickcontrols
    ];
    installPhase = ''
      mkdir -p $out/share/sddm/themes
      cp -aR $src $out/share/sddm/themes/chili
    '';
    src = fetchFromGitHub {
      owner = "MarianArlt";
      repo = pname;
      rev = version;
      sha256 = "sha256-wxWsdRGC59YzDcSopDRzxg8TfjjmA3LHrdWjepTuzgw=";
    };
  };
}
