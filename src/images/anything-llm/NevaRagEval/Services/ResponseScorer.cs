using System.Text.RegularExpressions;

namespace Neva.RagEval.Services;

public static class ResponseScorer
{
  private static readonly string[] RefusalMarkers =
  [
    "нет в документ",
    "в документации портала этого нет",
    "в документации этого нет",
    "в инженерной базе этого нет",
    "полного кода",
    "нет в индексе",
    "инженерн",
    "neva dwh engineer",
    "portal helper",
    "отказ",
    "не знаю",
    "нет в контекст",
    "на портале нет",
    "нет, на портале",
  ];

  public static (double score, List<string> matched, List<string> failed) Score(
    string answer,
    string expectedHint
  )
  {
    var matched = new List<string>();
    var failed = new List<string>();
    var lower = answer.ToLowerInvariant();
    var rules = BuildRules(expectedHint);

    if (rules.Count == 0)
    {
      matched.Add("(no rules — non-empty answer)");
      return (string.IsNullOrWhiteSpace(answer) ? 0 : 0.5, matched, failed);
    }

    var groups = rules.GroupBy(r => r.Group).ToList();
    var groupHits = 0;

    foreach (var group in groups)
    {
      var anyHit = false;
      foreach (var rule in group)
      {
        if (rule.Kind == RuleKind.Refusal)
        {
          if (RefusalMarkers.Any(m => lower.Contains(m, StringComparison.Ordinal)))
          {
            matched.Add(rule.Label);
            anyHit = true;
          }
        }
        else if (rule.Kind == RuleKind.Path)
        {
          if (ContainsPath(answer, rule.Needle))
          {
            matched.Add(rule.Label);
            anyHit = true;
          }
        }
        else if (rule.Kind == RuleKind.Keyword)
        {
          if (lower.Contains(rule.Needle, StringComparison.Ordinal) ||
              ContainsKeyword(lower, rule.Needle))
          {
            matched.Add(rule.Label);
            anyHit = true;
          }
        }
      }

      if (anyHit) groupHits++;
      else failed.Add(string.Join(" OR ", group.Select(g => g.Label)));
    }

    var score = groups.Count == 0 ? 0 : (double)groupHits / groups.Count;
    return (score, matched, failed);
  }

  private static List<Rule> BuildRules(string expected)
  {
    var rules = new List<Rule>();
    var text = expected.Trim();

    // Paths: `/generator/`, `/app/` (not RabbitMQ/Kafka)
    foreach (Match m in Regex.Matches(text, @"(?<![\p{L}\p{Nd}])/[\p{L}\p{Nd}._-]+/?", RegexOptions.IgnoreCase))
    {
      var path = m.Value.Trim().ToLowerInvariant();
      rules.Add(new Rule(0, RuleKind.Path, path, path));
    }

    // отказ / Portal Helper
    if (text.Contains("отказ", StringComparison.OrdinalIgnoreCase) ||
        text.Contains("Portal Helper", StringComparison.OrdinalIgnoreCase) ||
        text.Contains("инженерн", StringComparison.OrdinalIgnoreCase) ||
        text.Contains("нет в документации", StringComparison.OrdinalIgnoreCase) ||
        text.Contains("полного кода нет", StringComparison.OrdinalIgnoreCase) ||
        text.Contains("нет в индексе", StringComparison.OrdinalIgnoreCase))
    {
      rules.Add(new Rule(1, RuleKind.Refusal, "refusal", "отказ/инженер"));
    }

    // OR groups split by « vs » or « или »
    var vsParts = Regex.Split(text, @"\s+vs\s+|\s+или\s+", RegexOptions.IgnoreCase);
    if (vsParts.Length > 1)
    {
      for (var i = 0; i < vsParts.Length; i++)
      {
        var part = vsParts[i];
        foreach (Match m in Regex.Matches(part, @"[a-zа-яё0-9./_-]{4,}", RegexOptions.IgnoreCase))
        {
          var token = m.Value.ToLowerInvariant();
          if (token.StartsWith("http")) continue;
          rules.Add(new Rule(10 + i, RuleKind.Keyword, token, token));
        }
      }
    }

    // Keywords from backticks
    foreach (Match m in Regex.Matches(text, @"`([^`]+)`"))
      rules.Add(new Rule(2, RuleKind.Keyword, m.Groups[1].Value.ToLowerInvariant(), m.Groups[1].Value));

    // CamelCase API names: SendMsg, GetMsg
    foreach (Match m in Regex.Matches(text, @"\b[A-Z][a-z]+[A-Z][a-zA-Z]*\b"))
      rules.Add(new Rule(5, RuleKind.Keyword, m.Value.ToLowerInvariant(), m.Value));

    // Named tokens (MAE, VIX, TTM, mq, etc.)
    foreach (Match m in Regex.Matches(text, @"\b[A-Z]{2,}\b"))
      rules.Add(new Rule(3, RuleKind.Keyword, m.Value.ToLowerInvariant(), m.Value));

    if (text.Contains("TTM", StringComparison.OrdinalIgnoreCase))
      rules.Add(new Rule(3, RuleKind.Keyword, "time-to-market", "TTM"));

    if (rules.Count == 0)
    {
      foreach (Match m in Regex.Matches(text, @"[a-zа-яё0-9]{5,}", RegexOptions.IgnoreCase))
      {
        var token = m.Value.ToLowerInvariant();
        rules.Add(new Rule(4, RuleKind.Keyword, token, token));
      }
    }

    return rules
      .GroupBy(r => $"{r.Group}:{r.Label}")
      .Select(g => g.First())
      .ToList();
  }

  private static bool ContainsPath(string answer, string path)
  {
    var lower = answer.ToLowerInvariant();
    var norm = path.Trim().TrimEnd('/').ToLowerInvariant();
    if (string.IsNullOrEmpty(norm)) return false;
    if (lower.Contains(norm, StringComparison.Ordinal)) return true;
    if (lower.Contains(norm + "/", StringComparison.Ordinal)) return true;

    // https://host/docs/foo matches /docs/foo
    var idx = lower.IndexOf("://", StringComparison.Ordinal);
    if (idx >= 0)
    {
      var afterHost = lower[(idx + 3)..];
      var slash = afterHost.IndexOf('/');
      if (slash >= 0)
      {
        var urlPath = afterHost[slash..].TrimEnd('/');
        if (urlPath.Equals(norm, StringComparison.Ordinal) ||
            urlPath.StartsWith(norm + "/", StringComparison.Ordinal))
          return true;
      }
    }

    return false;
  }

  private static bool ContainsKeyword(string lower, string needle)
  {
    if (lower.Contains(needle, StringComparison.Ordinal)) return true;
    if (needle.Length < 5) return false;
    var stem = needle[..Math.Min(needle.Length - 1, 6)];
    return lower.Contains(stem, StringComparison.Ordinal);
  }

  private enum RuleKind { Path, Keyword, Refusal }

  private sealed record Rule(int Group, RuleKind Kind, string Needle, string Label);
}
