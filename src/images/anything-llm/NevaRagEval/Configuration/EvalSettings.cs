namespace Neva.RagEval.Configuration;

public sealed class EvalSettings
{
  public string RagRoot { get; set; } = "../rag";
  public string Corpus { get; set; } = "portal";
  public string OllamaBaseUrl { get; set; } = "http://localhost:11434";
  public string ChatModel { get; set; } = "llama3";
  public string EmbeddingModel { get; set; } = "nomic-embed-text";
  public string BaseUrl { get; set; } = "https://dwh.neva.cloudns.nz";
  public int TopK { get; set; } = 4;
  public bool UseEmbeddings { get; set; }
  public double MinPassScore { get; set; } = 0.6;
  public int RequestTimeoutSeconds { get; set; } = 120;
  public string OutputDirectory { get; set; } = "eval-results";
  public string? Question { get; set; }
  public int? ScenarioId { get; set; }
  public bool ListOnly { get; set; }
}
