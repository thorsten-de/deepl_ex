defmodule DeeplEx do
  alias Tesla.Middleware
  alias DeeplEx.{Language, Translation}

  @adapter {Tesla.Adapter.Finch, name: DeeplFinch}

  defp client do
    api_key = Application.fetch_env!(:deepl_ex, :api_key)

    [
      {Tesla.Middleware.BaseUrl, get_api_url(api_key)},
      {Tesla.Middleware.Headers, [{"Authorization", "DeepL-Auth-Key #{api_key}"}]},
      Tesla.Middleware.EncodeFormUrlencoded,
      Tesla.Middleware.DecodeJson
    ]
    |> Tesla.client(@adapter)
  end

  defp get_api_url(api_key) do
    if String.ends_with?(api_key, ":fx") do
      "https://api-free.deepl.com/v2"
    else
      "https://api.deepl.com/v2"
    end
  end

  defp handle_result({:ok, %{status: 200, body: body}}, f) do
    f.(body)
  end

  defp handle_result({:ok, %{status: status, body: %{"message" => message}}}, _f) do
    {:error, %{status: status, message: message}}
  end

  defp handle_result({:ok, result}, _f) do
    {:error, Map.take(result, [:status, :body])}
  end

  @spec usage :: %{left: number, limit: number, used: number} | {:error, map}
  @doc """
  Retrieve usage information within the current billing period
  """
  def usage do
    client()
    |> Tesla.get("usage")
    |> handle_result(&parse_usage/1)
  end

  @spec languages(:source | :target) :: list | {:error, map}
  @doc """
  Retrieve list of supported languages for translation, either as source or target language
  """
  def languages(type \\ :source) when type in [:target, :source] do
    client()
    |> Tesla.get("languages", query: [type: type])
    |> handle_result(&parse_languages/1)
  end

  @spec translate(list | map) :: list | {:error, map}
  @doc """
  Request a translation, see https://www.deepl.com/de/docs-api/translate-text/ for details. While there
  are many optional parameters, these are the *required parameters*:
    - text
    - target_lang
  """
  def translate(data),
    do:
      client()
      |> Tesla.post("translate", data)
      |> handle_result(&parse_translations(&1, target_lang: data[:target_lang]))

  defp parse_translations(%{"translations" => translations}, opts),
    do:
      translations
      |> Enum.map(&Translation.from_result(&1, opts))

  defp parse_languages(languages),
    do:
      languages
      |> Enum.map(&Language.from_result/1)

  defp parse_usage(%{"character_count" => used, "character_limit" => limit}),
    do: %{used: used, limit: limit, left: limit - used}
end
