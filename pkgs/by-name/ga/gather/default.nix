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
    rev = "1c19003d3e069d6355fc27aa5f180df715a9658c";
    hash = "sha256-KpE7NpiafssjmPJHixq6dMoeCmPQH4ZS1zbLkS6VDls=";
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
