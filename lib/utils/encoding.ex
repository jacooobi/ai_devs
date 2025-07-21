defmodule Utils.Encoding do
  def fix(data) when is_map(data) do
    data
    |> Enum.reduce(%{}, fn {id, value}, acc ->
      result =
        case value do
          list when is_list(list) -> Enum.map(list, &String.replace(&1, "\u00A0", " "))
          str when is_binary(str) -> String.replace(str, "\u00A0", " ")
        end

      Map.put(acc, id, result)
    end)
    |> then(&{:ok, &1})
  end

  def fix(data) when is_list(data) do
    data
    |> Enum.map(&String.replace(&1, "\u00A0", " "))
    |> then(&{:ok, &1})
  end
end
