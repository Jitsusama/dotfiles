{
  lib,
  buildNpmPackage,
  agentic-harness-core,
}:

buildNpmPackage {
  pname = "agentic-harness-core";
  version = "0.1.0";

  src = agentic-harness-core;

  npmDepsHash = "sha256-DMiCZKMC6LviJuifIrtuak2DjFv3Qe2XD9OrjUWKg2E=";

  meta = {
    description = "Pi-agnostic business logic for agentic-harness (state machines, guardian decisions, quest/TDD domain model), exposed as a CLI";
    homepage = "https://github.com/Jitsusama/agentic-harness.core";
    license = lib.licenses.mit;
    mainProgram = "agentic-harness-core";
    platforms = lib.platforms.unix;
  };
}
