{ pkgs }:
pkgs.python3Packages.buildPythonApplication rec {
  pname = "gidged";
  version = "0.0.1";
  pyproject = false;
  propagatedBuildInputs = with pkgs; [
    git
  ];
  dontUnpack = true;
  installPhase = # bash
    ''
      install -Dm755 "${./src/main.py}" "$out/bin/${pname}"
    '';
}
