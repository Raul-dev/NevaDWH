using System.Text;
using System.Text.RegularExpressions;
using Neva.RagEval.Models;

namespace Neva.RagEval.Services;

public static class EvalScenarioParser
{
  public static IReadOnlyList<EvalScenario> ParseFile(string path)
  {
    if (!File.Exists(path))
      throw new FileNotFoundException($"Eval file not found: {path}");

    var lines = File.ReadAllLines(path, Encoding.UTF8);
    var scenarios = new List<EvalScenario>();

    foreach (var line in lines)
    {
      if (!line.StartsWith('|')) continue;
      if (line.Contains("---|")) continue;
      if (line.Contains("# |")) continue;
      if (line.Contains("Вопрос")) continue;

      var cells = line.Split('|', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries);
      if (cells.Length < 3) continue;
      if (!int.TryParse(cells[0], out var id)) continue;

      scenarios.Add(new EvalScenario(id, cells[1], cells[2]));
    }

    return scenarios;
  }
}
