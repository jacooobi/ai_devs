defmodule Lessons.S01E05.Main do
  @task "CENZURA"

  def run() do
    {:ok, file_data} = fetch_file()
    {:ok, answer} = anynonymize_contents(file_data)
    {:ok, _flag} = Utils.AIDevs.submit(@task, answer)
  end

  defp fetch_file() do
    url = file_url()

    url
    |> HTTPoison.get()
    |> then(fn {:ok, %{body: body}} -> {:ok, body} end)
  end

  defp anynonymize_contents(text) do
    instructions = """
      Zamień następujące informacje na słowo "CENZURA":
        *   Imię i nazwisko (razem, np. "Jan Nowak" -> "CENZURA")
        *   Wiek (np. "32" -> "CENZURA")
        *   Miasto (np. "Wrocław" -> "CENZURA")
        *   Ulica i numer domu (razem, np. "ul. Szeroka 18" -> "ul. CENZURA")
      Zachowaj oryginalny format tekstu (kropki, przecinki, spacje). Nie wolno Ci przeredagowywać tekstu.
    """

    Utils.OpenAI.responses(text, instructions: instructions, model: "gpt-4.1")
  end

  defp api_key(), do: Application.get_env(:ai_devs, :api_key)
  defp base_url(), do: Application.get_env(:ai_devs, :base_url)
  defp file_url(), do: base_url() <> "/data/" <> api_key() <> "/cenzura.txt"
end
