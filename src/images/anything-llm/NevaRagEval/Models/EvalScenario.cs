namespace Neva.RagEval.Models;

public sealed record EvalScenario(int Id, string Question, string ExpectedHint);

public sealed record RagChunk(string SourceFile, string Title, string Text, float[]? Embedding);

public sealed record EvalRunResult(
  EvalScenario Scenario,
  string Answer,
  double Score,
  bool Passed,
  IReadOnlyList<string> MatchedRules,
  IReadOnlyList<string> FailedRules,
  IReadOnlyList<string> ContextSources
);
