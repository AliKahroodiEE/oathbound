/// Deterministic progression rules for Wyrd.
///
/// The authoritative specification is `docs/product/progression-rules.md`.
/// A TypeScript twin runs on the server; both must pass the conformance
/// vectors in `test/vectors/`.
library;

export 'src/consistency.dart';
export 'src/curves.dart';
export 'src/engine.dart';
export 'src/facts.dart';
export 'src/heuristic.dart';
export 'src/model.dart';
export 'src/proposal.dart';
export 'src/recognition.dart';
export 'src/result.dart';
export 'src/rules.dart' show rulesVersion;
