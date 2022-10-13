defmodule DeeplEx.Translation do
  defstruct [:source_lang, :target_lang, :text]

  def from_result(%{"detected_source_language" => source, "text" => text}, opts \\ []) do
    %__MODULE__{
      source_lang: source,
      text: text,
      target_lang: opts[:target_lang]
    }
  end
end
