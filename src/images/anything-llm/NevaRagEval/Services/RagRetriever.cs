using System.Text.RegularExpressions;
using Neva.RagEval.Models;

namespace Neva.RagEval.Services;

public sealed class RagRetriever
{
  private readonly IReadOnlyList<RagChunk> _chunks;
  private readonly bool _useEmbeddings;
  private readonly OllamaClient _ollama;
  private readonly string _embeddingModel;

  public RagRetriever(
    IReadOnlyList<RagChunk> chunks,
    bool useEmbeddings,
    OllamaClient ollama,
    string embeddingModel
  )
  {
    _chunks = chunks;
    _useEmbeddings = useEmbeddings;
    _ollama = ollama;
    _embeddingModel = embeddingModel;
  }

  public async Task<IReadOnlyList<RagChunk>> RetrieveAsync(string query, int topK, CancellationToken ct)
  {
    if (_chunks.Count == 0) return Array.Empty<RagChunk>();

    if (_useEmbeddings)
    {
      try
      {
        var queryVec = await _ollama.EmbedAsync(_embeddingModel, query, ct);
        var scored = new List<(RagChunk chunk, double score)>();

        foreach (var chunk in _chunks)
        {
          var vec = chunk.Embedding ?? await _ollama.EmbedAsync(_embeddingModel, chunk.Text, ct);
          scored.Add((chunk with { Embedding = vec }, Cosine(queryVec, vec)));
        }

        return scored
          .OrderByDescending(x => x.score)
          .Take(topK)
          .Select(x => x.chunk)
          .ToList();
      }
      catch
      {
        // fallback to lexical if embedding model missing
      }
    }

    var terms = Tokenize(query);
    return _chunks
      .Select(c =>
      {
        var score = ScoreLexical(c.Text, terms);
        if (c.SourceFile.Contains("_curated", StringComparison.OrdinalIgnoreCase))
          score *= 2.0;
        return (chunk: c, score);
      })
      .Where(x => x.score > 0)
      .OrderByDescending(x => x.score)
      .Take(topK)
      .Select(x => x.chunk)
      .ToList();
  }

  private static double ScoreLexical(string text, IReadOnlyList<string> terms)
  {
    var lower = text.ToLowerInvariant();
    double score = 0;
    foreach (var term in terms)
    {
      if (lower.Contains(term, StringComparison.Ordinal))
        score += term.Length >= 5 ? 2 : 1;
    }
    return score;
  }

  private static List<string> Tokenize(string query)
  {
    return Regex.Split(query.ToLowerInvariant(), @"[^\p{L}\p{Nd}/]+")
      .Where(t => t.Length >= 3)
      .Distinct()
      .ToList();
  }

  private static double Cosine(float[] a, float[] b)
  {
    if (a.Length != b.Length) return 0;
    double dot = 0, na = 0, nb = 0;
    for (var i = 0; i < a.Length; i++)
    {
      dot += a[i] * b[i];
      na += a[i] * a[i];
      nb += b[i] * b[i];
    }
    if (na == 0 || nb == 0) return 0;
    return dot / (Math.Sqrt(na) * Math.Sqrt(nb));
  }
}
