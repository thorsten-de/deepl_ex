defmodule DeeplEx.Language do
  defstruct [:language, :name, :supports_formality?]

  def from_result(map),
    do: %__MODULE__{
      language: map["language"],
      name: map["name"],
      supports_formality?: map["supports_formality"]
    }
end
