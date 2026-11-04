{
  lib,
  pkgs,
  fetchFromGitea,
}:
pkgs.python3Packages.buildPythonApplication rec {
  pname = "gather";
  version = "0.1.0";

  src = fetchFromGitea {
    domain = "gitea.x.home.arpa";
    owner = "python";
    repo = "gather";
    rev = "2b9f551";
    hash = "sha256-zogl7KzgOTlKQWKJeUncql7iNjz1M+v61BjeDnuhXkA=";
  };

  pyproject = true;
  build-system = [ pkgs.python3Packages.uv-build ];

  # nixpkgs ships uv-build 0.12.5; gather's pyproject pins >=0.13.4. Relax the
  # build-system constraint so the (stable) PEP 517 backend resolves. Drop this
  # once gather relaxes its own constraint.
  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace 'uv_build>=0.13.4,<0.14.0' 'uv_build>=0.12'
  '';

  propagatedBuildInputs = with pkgs; [
    git
  ];

  meta = with lib; {
    description = "Bootstrap git repos, their wikis, and worktrees in one opinionated layout";
    homepage = "https://gitea.x.home.arpa/python/gather";
    license = licenses.lgpl3;
    mainProgram = "gather";
  };
}
