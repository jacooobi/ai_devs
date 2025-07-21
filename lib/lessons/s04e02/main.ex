defmodule Lessons.S04E02.Main do
  @task "research"

  def run do
    {:ok, input} = fetch_input_data()
    {:ok, answer} = run_analysis(input)

    {:ok, _flag} = Utils.AIDevs.submit(@task, answer)
  end

  defp fetch_input_data(), do: File.read(input_path())

  defp run_analysis(input) do
    input
    |> String.split("\n")
    |> Enum.map(fn row ->
      row
      |> String.split("=")
      |> then(fn [idx, text] ->
        text
        |> categorise()
        |> then(fn {:ok, response} -> {idx, response} end)
      end)
    end)
    |> Enum.filter(fn {_idx, response} -> response != "0" end)
    |> Enum.map(fn {idx, _response} -> idx end)
    |> then(&{:ok, &1})
  end

  defp categorise(input) do
    instructions = "Categorise the following text into one of the categories: 0 or 1"

    Utils.OpenAI.responses(input, instructions: instructions, model: fine_tuned_model())
  end

  defp fine_tuned_model(), do: Application.get_env(:ai_devs, :fine_tuned_model)

  defp input_directory(), do: "lib/lessons/s04e02/input/"
  defp input_path(), do: Path.join(File.cwd!(), [input_directory(), "verify.txt"])
end
