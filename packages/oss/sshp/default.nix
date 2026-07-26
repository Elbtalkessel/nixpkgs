{
  stdenv,
  fetchFromGitHub,
  lib,
  nix-update-script,
}:
# TODO: add doCheck = true and `make test`, complains about:
#   ./tools/check: /usr/bin/env: bad interpreter: No such file or directory atm
stdenv.mkDerivation (finalAttrs: {
  pname = "sshp";
  version = "1.1.4";
  src = fetchFromGitHub {
    owner = "bahamas10";
    rev = "v${finalAttrs.version}";
    repo = finalAttrs.pname;
    sha256 = "sha256-4DrNGQQ1ETKuLiB3N+3KnRxx4BEhrCOgskpowbF/KWc=";
  };
  strictDeps = true;
  makeFlags = [ "PREFIX=$(out)" ];
  passthru.updateScript = nix-update-script { };
  meta = {
    description = "Parallel SSH Executor";
    homepage = "https://github.com/bahamas10/sshp";
    license = lib.licenses.mit;
    mainProgram = "sshp";
  };
})
