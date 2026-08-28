using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace Neva.RagEval.Services;

public sealed class OllamaClient : IDisposable
{
  private readonly HttpClient _http;
  private readonly TimeSpan _timeout;

  public OllamaClient(string baseUrl, int timeoutSeconds)
  {
    _timeout = TimeSpan.FromSeconds(timeoutSeconds);
    _http = new HttpClient { BaseAddress = new Uri(baseUrl.TrimEnd('/') + "/") };
    _http.Timeout = _timeout;
  }

  public async Task<bool> PingAsync(CancellationToken ct)
  {
    try
    {
      var res = await _http.GetAsync("api/tags", ct);
      return res.IsSuccessStatusCode;
    }
    catch
    {
      return false;
    }
  }

  public async Task<string> ChatAsync(
    string model,
    string systemPrompt,
    string userMessage,
    CancellationToken ct
  )
  {
    var payload = new
    {
      model,
      stream = false,
      messages = new[]
      {
        new { role = "system", content = systemPrompt },
        new { role = "user", content = userMessage },
      },
      options = new { temperature = 0.2, num_predict = 512 },
    };

    using var req = new HttpRequestMessage(HttpMethod.Post, "api/chat")
    {
      Content = new StringContent(JsonSerializer.Serialize(payload), Encoding.UTF8, "application/json"),
    };

    using var res = await _http.SendAsync(req, ct);
    res.EnsureSuccessStatusCode();

    var body = await res.Content.ReadFromJsonAsync<OllamaChatResponse>(cancellationToken: ct);
    return body?.Message?.Content?.Trim() ?? "";
  }

  public async Task<float[]> EmbedAsync(string model, string text, CancellationToken ct)
  {
    var payload = new { model, input = text };
    using var res = await _http.PostAsJsonAsync("api/embeddings", payload, ct);
    res.EnsureSuccessStatusCode();
    var body = await res.Content.ReadFromJsonAsync<OllamaEmbedResponse>(cancellationToken: ct);
    return body?.Embedding ?? Array.Empty<float>();
  }

  public void Dispose() => _http.Dispose();

  private sealed class OllamaChatResponse
  {
    [JsonPropertyName("message")]
    public OllamaMessage? Message { get; set; }
  }

  private sealed class OllamaMessage
  {
    [JsonPropertyName("content")]
    public string? Content { get; set; }
  }

  private sealed class OllamaEmbedResponse
  {
    [JsonPropertyName("embedding")]
    public float[]? Embedding { get; set; }
  }
}
