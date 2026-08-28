using Microsoft.Extensions.Configuration;
using Neva.RagEval.Configuration;
using Neva.RagEval.Services;

namespace Neva.RagEval;

internal static class Program
{
  public static async Task<int> Main(string[] args)
  {
    var settings = LoadSettings(args);
    var ragRoot = Path.GetFullPath(settings.RagRoot);
    var corpusDir = Path.Combine(ragRoot, settings.Corpus);
    var evalFile = Path.Combine(corpusDir, "eval-questions.md");

    Console.WriteLine("Neva RAG Eval — Ollama query-mode smoke tests");
    Console.WriteLine($"Corpus: {corpusDir}");
    Console.WriteLine($"Ollama: {settings.OllamaBaseUrl} model={settings.ChatModel}");
    Console.WriteLine();

    if (!Directory.Exists(corpusDir))
    {
      Console.Error.WriteLine($"ERROR: corpus directory not found: {corpusDir}");
      return 1;
    }

    var systemPrompt = CorpusLoader.LoadSystemPrompt(corpusDir, settings.BaseUrl);
    var chunks = CorpusLoader.LoadChunks(corpusDir, settings.BaseUrl);
    Console.WriteLine($"Loaded {chunks.Count} RAG chunks, system prompt {systemPrompt.Length} chars");

    using var ollama = new OllamaClient(settings.OllamaBaseUrl, settings.RequestTimeoutSeconds);
    if (!await ollama.PingAsync(CancellationToken.None))
    {
      Console.Error.WriteLine("ERROR: Ollama not reachable. Start ollama or set OllamaBaseUrl.");
      return 2;
    }

    var retriever = new RagRetriever(chunks, settings.UseEmbeddings, ollama, settings.EmbeddingModel);
    var runner = new EvalRunner(settings, systemPrompt, retriever, ollama);

    if (!string.IsNullOrWhiteSpace(settings.Question))
    {
      var scenario = new Models.EvalScenario(0, settings.Question, "(manual)");
      var result = await runner.RunOneAsync(scenario, CancellationToken.None);
      EvalRunner.PrintSummary([result], settings.MinPassScore);
      return result.Passed ? 0 : 3;
    }

    var scenarios = EvalScenarioParser.ParseFile(evalFile);
    if (settings.ScenarioId is int onlyId)
      scenarios = scenarios.Where(s => s.Id == onlyId).ToList();

    if (settings.ListOnly)
    {
      foreach (var s in scenarios)
        Console.WriteLine($"#{s.Id} {s.Question} => {s.ExpectedHint}");
      return 0;
    }

    if (scenarios.Count == 0)
    {
      Console.Error.WriteLine($"No scenarios in {evalFile}");
      return 4;
    }

    Console.WriteLine($"Running {scenarios.Count} scenarios from eval-questions.md");
    Console.WriteLine();

    var results = await runner.RunAllAsync(scenarios, CancellationToken.None);
    EvalRunner.PrintSummary(results, settings.MinPassScore);

    var outDir = Path.GetFullPath(settings.OutputDirectory);
    await EvalRunner.SaveReportAsync(outDir, settings.Corpus, results, CancellationToken.None);

    var passRate = (double)results.Count(r => r.Passed) / results.Count;
    return passRate >= settings.MinPassScore ? 0 : 3;
  }

  private static EvalSettings LoadSettings(string[] args)
  {
    var config = new ConfigurationBuilder()
      .SetBasePath(AppContext.BaseDirectory)
      .AddJsonFile("appsettings.json", optional: true)
      .AddEnvironmentVariables("NEVA_RAG_EVAL_")
      .Build();

    var settings = new EvalSettings();
    config.Bind(settings);
    ApplyArgs(settings, args);
    return settings;
  }

  private static void ApplyArgs(EvalSettings s, string[] args)
  {
    for (var i = 0; i < args.Length; i++)
    {
      var a = args[i];
      string? Next() => i + 1 < args.Length ? args[++i] : null;

      switch (a)
      {
        case "--corpus":
        case "-c":
          s.Corpus = Next() ?? s.Corpus;
          break;
        case "--rag-root":
          s.RagRoot = Next() ?? s.RagRoot;
          break;
        case "--ollama":
          s.OllamaBaseUrl = Next() ?? s.OllamaBaseUrl;
          break;
        case "--model":
        case "-m":
          s.ChatModel = Next() ?? s.ChatModel;
          break;
        case "--base-url":
          s.BaseUrl = Next() ?? s.BaseUrl;
          break;
        case "--top-k":
          if (int.TryParse(Next(), out var k)) s.TopK = k;
          break;
        case "--embeddings":
          s.UseEmbeddings = true;
          break;
        case "--question":
        case "-q":
          s.Question = Next();
          break;
        case "--id":
          if (int.TryParse(Next(), out var id)) s.ScenarioId = id;
          break;
        case "--list":
          s.ListOnly = true;
          break;
        case "--min-pass":
          if (double.TryParse(Next(), System.Globalization.NumberStyles.Float, System.Globalization.CultureInfo.InvariantCulture, out var mp))
            s.MinPassScore = mp;
          break;
        case "--help":
        case "-h":
          PrintHelp();
          Environment.Exit(0);
          break;
      }
    }
  }

  private static void PrintHelp()
  {
    Console.WriteLine("""
      neva-rag-eval — load RAG + prompts, query Ollama, run eval-questions.md

      Usage:
        dotnet run --project NevaRagEval -- --corpus portal
        dotnet run --project NevaRagEval -- --corpus engineer --model qwen2.5
        dotnet run --project NevaRagEval -- -q "Где документация?"
        dotnet run --project NevaRagEval -- --corpus portal --id 2

      Options:
        --corpus, -c     portal | engineer (default portal)
        --rag-root       path to rag/ (default ../rag)
        --ollama         Ollama URL (default http://localhost:11434)
        --model, -m      chat model (llama3 | qwen2.5)
        --base-url       NEVA_RAG_BASE_URL for prompt substitution
        --top-k          RAG chunks (default 4)
        --embeddings     use Ollama embeddings (needs nomic-embed-text)
        --question, -q   single ad-hoc question
        --id             run one scenario by number
        --list           list scenarios only
        --min-pass       pass threshold 0..1 (default 0.6)

      Env: NEVA_RAG_EVAL_ChatModel, NEVA_RAG_EVAL_OllamaBaseUrl, ...
      """);
  }
}
