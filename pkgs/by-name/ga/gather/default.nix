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
    rev = "aebfa67e9579602e6773a279bb8d4db6d9cfc3af";
    hash = "sha256-pL6Qxh6lMEV3/a/5TjyqHYw1mguFMC39f8QSd4QKjsQ=";
  };

  pyproject = true;
  build-system = [ pkgs.python3Packages.uv-build ];

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
