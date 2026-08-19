{
  lib,
  buildNpmPackage,
  fetchurl,
}:

buildNpmPackage rec {
  pname = "pi-coding-agent";
  version = "0.84.2";

  # Pi publishes a self-contained tarball (prebuilt `dist/`, no monorepo
  # build tooling required), so we fetch it straight from the registry
  # instead of building the earendil-works/pi monorepo from source.
  src = fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-lbiZzXsaDB8BdMe/M6tCdDXjVTp9H0dWZhqpx/Gmj/o=";
  };

  # The published npm-shrinkwrap.json omits integrity hashes for the sibling
  # @earendil-works/* packages, which breaks buildNpmPackage's dependency
  # fetcher. Swap in a package-lock.json regenerated with
  # `npm install --package-lock-only` against the same dependency versions.
  postPatch = ''
    rm -f npm-shrinkwrap.json
    cp ${./package-lock.json} package-lock.json
  '';

  npmDepsHash = "sha256-x19UPXNlD/aYZdg8gaAjqKZot28UDOfbnP7HY8HqmGU=";

  dontNpmBuild = true;

  meta = {
    description = "Minimal terminal coding harness, extensible with TypeScript extensions, skills, and prompt templates";
    homepage = "https://github.com/earendil-works/pi";
    license = lib.licenses.mit;
    mainProgram = "pi";
    platforms = lib.platforms.unix;
  };
}
