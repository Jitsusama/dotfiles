# pi, the coding agent, built from its npm release with the lock file
# beside this, for home.nix to install.
{
  lib,
  buildNpmPackage,
  fetchurl,
}:

buildNpmPackage rec {
  pname = "pi-coding-agent";
  version = "1.4.0";

  # Pi publishes a self-contained tarball (prebuilt `dist/`, no monorepo
  # build tooling required), so we fetch it straight from the registry
  # instead of building the earendil-works/pi monorepo from source.
  src = fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-0VXBbvb6AJYPv1iykRU26AsF8zcA4LFPvQiWft4MdCg=";
  };

  # The published npm-shrinkwrap.json omits integrity hashes for the sibling
  # @earendil-works/* packages, which breaks buildNpmPackage's dependency
  # fetcher. Swap in a package-lock.json regenerated with
  # `npm install --package-lock-only` against the same dependency versions.
  postPatch = ''
    rm -f npm-shrinkwrap.json
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-npDQwvrXeoxvoK/ItLeB4q5UGEbslZ9onOlgclM8IcI=";

  dontNpmBuild = true;

  meta = {
    description = "Minimal terminal coding harness, extensible with TypeScript extensions, skills, and prompt templates";
    homepage = "https://github.com/earendil-works/pi";
    license = lib.licenses.mit;
    mainProgram = "pi";
    platforms = lib.platforms.unix;
  };
}
