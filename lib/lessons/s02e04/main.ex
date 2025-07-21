defmodule Lessons.S02E04.Main do
  @task "kategorie"

  def run() do
    if not Lessons.S02E04.Setup.done?(), do: Lessons.S02E04.Setup.perform()

    {:ok, data_for_analysis} = retrieve_input()
    {:ok, categorised_data} = categorise(data_for_analysis)
    {:ok, answer} = prepare_for_submission(categorised_data)

    {:ok, _flag} = Utils.AIDevs.submit(@task, answer)
  end

  defp prepare_for_submission(data) do
    data
    |> Enum.filter(fn {category, _} -> category in ["people", "hardware"] end)
    |> Enum.group_by(fn {category, _} -> category end, fn {_, value} -> value end)
    |> Enum.map(fn {key, list} -> {key, Enum.sort(list)} end)
    |> Enum.into(%{})
    |> then(&{:ok, &1})
  end

  defp retrieve_input() do
    path = processed_input_path()

    path
    |> File.ls!()
    |> Enum.map(fn file ->
      file_path = Path.join([path, file])

      {file, File.read!(file_path)}
    end)
    |> then(&{:ok, &1})
  end

  defp categorise(data) do
    Enum.map(data, fn {file, contents} ->
      {:ok, category} = run_categorisation(contents)

      {category, file}
    end)
    |> then(&{:ok, &1})
  end

  defp run_categorisation(contents) do
    instructions =
      """
        Analizujac text ustal czy dotyczy on jednej z dwoch kategorii:

        people:
          Uwzględniaj tylko notatki zawierające informacje o schwytanych ludziach lub o śladach ich obecności.
          Jezeli w raporcie jest podana wprost informacja o nieznalezieniu osoby, to nie uwzgledniaj raportu w tej kategorii.
          Upewnij sie, ze raport faktycznie dotyczy schwytania lub podejrzanej osoby a nie dowolnej osoby w okolicy.


        hardware:
          Usterki hardwarowe (ALE NIE software).

        Jezeli nie pasuje do zadnej z kategorii, ustal, ze pasuje do 'other'

        Odpowiadaj wyłącznie jednym słowem - nazwą kategorii, do której pasuje tekst.
      """

    Utils.OpenAI.responses(contents, instructions: instructions, model: "gpt-4.1")
  end

  def input_path(), do: Path.join(File.cwd!(), input_files_directory())
  def processed_input_path(), do: Path.join(File.cwd!(), processed_files_directory())
  def output_path(file), do: Path.join(File.cwd!(), [processed_files_directory(), file])

  def input_files_directory(), do: "lib/lessons/s02e04/input/"
  def processed_files_directory(), do: "lib/lessons/s02e04/processed_input/"
end
