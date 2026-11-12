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
    rev = "f0c0fab17480bbdb3ef67e98abb1e9ffaf99824d";
    hash = "sha256-6eZxr6vhQLPfbmrBCU7PuGdfZhHduFZQE+gaHGY8sCA=";
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
