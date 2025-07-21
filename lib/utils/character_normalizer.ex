defmodule Utils.CharacterNormalizer do
  @polish_to_latin %{
    ?ą => "a",
    ?ć => "c",
    ?ę => "e",
    ?ł => "l",
    ?ń => "n",
    ?ó => "o",
    ?ś => "s",
    ?ż => "z",
    ?ź => "z",
    ?Ą => "A",
    ?Ć => "C",
    ?Ę => "E",
    ?Ł => "L",
    ?Ń => "N",
    ?Ó => "O",
    ?Ś => "S",
    ?Ż => "Z",
    ?Ź => "Z"
  }

  def normalize(str) when is_binary(str) do
    String.to_charlist(str)
    |> Enum.map(&Map.get(@polish_to_latin, &1, <<&1::utf8>>))
    |> Enum.join()
  end
end
