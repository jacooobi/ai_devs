defmodule Lessons.S03E01.Main do
  @task "dokumenty"

  def run() do
    if not Lessons.S03E01.Setup.done?(), do: Lessons.S03E01.Setup.perform()

    {:ok, context} = fetch_context()
    {:ok, report_data} = load_reports()
    {:ok, answer} = analyse_reports(report_data, context)
    {:ok, _flag} = Utils.AIDevs.submit(@task, answer)
  end

  def fetch_context(), do: File.read(Lessons.S03E01.Setup.final_document_path())

  def load_reports() do
    path = reports_input_path()

    path
    |> File.ls!()
    |> Enum.map(fn file ->
      file_path = Path.join(reports_input_path(), file)

      {file, File.read!(file_path)}
    end)
    |> then(&{:ok, &1})
  end

  def analyse_reports(report_data, context) do
    Enum.reduce(report_data, %{}, fn {file, data}, answers ->
      metadata = fetch_metadata(file)
      input = metadata <> "\n" <> data

      input
      |> generate_keywords(context)
      |> then(fn {:ok, keywords} ->
        Map.put(answers, file, keywords)
      end)
    end)
    |> then(&{:ok, &1})
  end

  def fetch_metadata(file) do
    date = get_date(file)
    report_id = get_report_id(file)
    sector = get_sector(file)

    "data : #{date}\n id: #{report_id}\n sektor: #{sector}"
  end

  def get_date(report) do
    report |> String.split("_") |> Enum.at(0)
  end

  def get_report_id(report) do
    report |> String.split("_") |> Enum.at(1) |> String.split("-") |> Enum.at(1)
  end

  def get_sector(report) do
    report |> String.split("_") |> Enum.at(-1) |> String.split(".") |> Enum.at(0)
  end

  def generate_keywords(text, context) do
    instructions = """
      Wygeneruj listę słów kluczowych, koncentrując się na ich jakości, nie ilości.
      Preferuj krótką listę terminów, które precyzyjnie i unikalnie opisują treść raportu oraz zawarte w nim fakty. Unikaj ogólników – słowa kluczowe powinny być jak najbardziej specyficzne dla danego dokumentu.
      -	Używaj formy mianownika i wyłącznie języka polskiego.
      -	Uwzględnij imiona i nazwiska, jeśli są istotne dla treści raportu.
      - Jeżeli raport dotyczy osoby, wśród słów kluczowych musi znaleźc się również ich zawód/profesję, np. nauczyciel lub programista.
      - Jeżeli raport dotyczy programisty frontend, słowo kluczowe powinno brzmiec javascript programmer.
      -	W razie potrzeby uogólniaj: np. „dzika fauna”, „zwierzyna leśna” lub „wildlife” można sprowadzić do „zwierzęta”, jeśli taka forma lepiej odpowiada kontekstowi walidacyjnemu.
      Prześlij wyłącznie słowa kluczowe, wylistowane po przecinku.

      Ponizej lista faktów, informacji z których powinieneń skorzystać aby wygenerować słowa kluczowe:

      #{context}
    """

    Utils.OpenAI.responses(text, instructions: instructions, model: "gpt-4.1")
  end

  defp base_directory(), do: "lib/lessons/s03e01/"

  defp reports_directory(), do: base_directory() <> "/input/reports/"
  defp reports_input_path(), do: Path.join(File.cwd!(), reports_directory())
end
