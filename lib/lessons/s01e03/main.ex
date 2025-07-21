defmodule Lessons.S01E03.Main do
  @task "JSON"

  def run() do
    {:ok, file_data} = fetch_file()
    {:ok, corrected_data} = fix_file(file_data)
    {:ok, answer} = prepare_for_submission(corrected_data)
    {:ok, _flag} = Utils.AIDevs.submit(@task, answer)
  end

  defp fetch_file() do
    url = file_url()

    url
    |> HTTPoison.get()
    |> then(fn {:ok, %{body: body}} -> JSON.decode(body) end)
  end

  defp fix_file(data) do
    test_data = Map.get(data, "test-data")

    corrected_test_data =
      Enum.map(test_data, fn
        %{"answer" => _answer, "question" => _question, "test" => _test} = row ->
          handle_with_ai(row)

        row ->
          handle_programatically(row)
      end)

    {:ok, Map.put(data, "test-data", corrected_test_data)}
  end

  defp handle_programatically(%{"question" => question}) do
    answer = question |> String.split(" + ") |> Enum.map(&String.to_integer(&1)) |> Enum.sum()

    %{"answer" => answer, "question" => question}
  end

  defp handle_with_ai(%{
         "answer" => answer,
         "question" => question,
         "test" => %{"q" => test_question}
       }) do
    {:ok, test_answer} = retrieve_answer(test_question)

    %{
      "answer" => answer,
      "question" => question,
      "test" => %{"a" => test_answer, "q" => test_question}
    }
  end

  defp retrieve_answer(question) do
    instructions = """
      You are a helpful assistant that provides concise answers.
      For any question, your will provide the answer in English and if possible, in a single word only.
    """

    Utils.OpenAI.responses(question, instructions: instructions)
  end

  defp prepare_for_submission(data) do
    {:ok, Map.put(data, "apikey", api_key())}
  end

  defp api_key(), do: Application.get_env(:ai_devs, :api_key)
  defp base_url(), do: Application.get_env(:ai_devs, :base_url)
  defp file_url(), do: base_url() <> "/data/" <> api_key() <> "/json.txt"
end
