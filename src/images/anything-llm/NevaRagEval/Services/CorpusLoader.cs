using System.Text;
using System.Text.RegularExpressions;
using Neva.RagEval.Models;

namespace Neva.RagEval.Services;

public static class CorpusLoader
{
  private static readonly Regex FrontMatter = new(@"^---\s*\n.*?\n---\s*\n", RegexOptions.Singleline);

  public static string LoadSystemPrompt(string corpusDir, string baseUrl)
  {
    var candidates = new[]
    {
      Path.Combine(corpusDir, "_curated", "system-prompt.txt"),
      Path.Combine(corpusDir, "system-prompt.txt"),
    };

    foreach (var path in candidates)
    {
      if (!File.Exists(path)) continue;
      var text = File.ReadAllText(path, Encoding.UTF8);
      return ApplyBaseUrl(text, baseUrl);
    }

    return "Ты — ассистент NevaDWH. Отвечай по-русски по контексту.";
  }

  public static IReadOnlyList<RagChunk> LoadChunks(string corpusDir, string baseUrl)
  {
    if (!Directory.Exists(corpusDir))
      throw new DirectoryNotFoundException($"Corpus not found: {corpusDir}");

    var chunks = new List<RagChunk>();
    foreach (var file in Directory.EnumerateFiles(corpusDir, "*.md", SearchOption.AllDirectories))
    {
      if (Path.GetFileName(file).Equals("eval-questions.md", StringComparison.OrdinalIgnoreCase))
        continue;

      var rel = Path.GetRelativePath(corpusDir, file).Replace('\\', '/');
      var raw = File.ReadAllText(file, Encoding.UTF8);
      raw = FrontMatter.Replace(raw, "");
      raw = ApplyBaseUrl(raw, baseUrl);

      foreach (var part in SplitMarkdown(raw))
      {
        if (string.IsNullOrWhiteSpace(part.Text)) continue;
        chunks.Add(new RagChunk(rel, part.Title, part.Text.Trim(), null));
      }
    }

    return chunks;
  }

  private static IEnumerable<(string Title, string Text)> SplitMarkdown(string markdown)
  {
    var sections = Regex.Split(markdown, @"(?=^#{1,3}\s)", RegexOptions.Multiline)
      .Where(s => !string.IsNullOrWhiteSpace(s))
      .ToList();

    if (sections.Count == 0)
    {
      if (markdown.Trim().Length >= 40)
        yield return ("document", markdown.Trim());
      yield break;
    }

    foreach (var section in sections)
    {
      var trimmed = section.Trim();
      if (trimmed.Length < 40) continue;

      var titleMatch = Regex.Match(trimmed, @"^#{1,3}\s+(.+)$", RegexOptions.Multiline);
      var title = titleMatch.Success ? titleMatch.Groups[1].Value.Trim() : "section";
      yield return (title, trimmed);
    }
  }

  private static string ApplyBaseUrl(string text, string baseUrl)
  {
    var baseNorm = baseUrl.TrimEnd('/');
    return text
      .Replace("{{NEVA_RAG_BASE_URL}}", baseNorm)
      .Replace("{{RAG_BASE_URL}}", baseNorm);
  }
}
