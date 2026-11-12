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
    rev = "f40d47530a76e9db90b1e035b5be10b69124c4b1";
    hash = "sha256-2yMAMoiZmyUVEch9LDq5A/fnm2Fx+3qU+BFMsBTNOwU=";
  };

  pyproject = true;
  build-system = [ pkgs.python3Packages.uv-build ];

  propagatedBuildInputs = with pkgs; [
    git
    # The `gather-mcp` entry point imports the MCP SDK at runtime; it is an
    # optional Python extra, so it is not pulled in by the pyproject build.
    python3Packages.mcp
  ];

  meta = with lib; {
    description = "Bootstrap git repos, their wikis, and worktrees in one opinionated layout";
    homepage = "https://gitea.x.home.arpa/python/gather";
    license = licenses.lgpl3;
    mainProgram = "gather";
  };
}
