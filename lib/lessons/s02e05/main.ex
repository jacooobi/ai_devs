defmodule Lessons.S02E05.Main do
  @task "arxiv"

  def run() do
    if not Lessons.S02E05.Setup.done?(), do: Lessons.S02E05.Setup.perform()

    {:ok, context} = load_context()
    {:ok, questions} = fetch_questions()

    {:ok, answers} = answer(context, questions)
    {:ok, _flag} = Utils.AIDevs.submit(@task, answers)
  end

  defp load_context() do
    path = Lessons.S02E05.Setup.final_document_path()

    case File.read(path) do
      {:ok, content} -> {:ok, content}
      {:error, reason} -> {:error, reason}
    end
  end

  def answer(context, questions) do
    instructions = """
      Odpowiedz w jednym zdaniu na zadane pytania w oparciu o następujący dokument:

      #{context}

      Odpowiedzi mają być w formacie JSON
      {
        "01": "odpowiedź na pytanie 01",
        "02": "odpowiedź na pytanie 02",
        "03": "odpowiedź na pytanie 03",
        ...
        "0n": "odpowiedź na pytanie 0n"
      }
    """

    questions
    |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4.1")
    |> then(fn {:ok, response} -> JSON.decode(response) end)
  end

  def fetch_questions() do
    case HTTPoison.get(questions_url()) do
      {:ok, %{status_code: 200, body: body}} -> {:ok, body}
      {:error, error} -> {:error, error}
    end
  end

  defp api_key(), do: Application.get_env(:ai_devs, :api_key)
  defp base_url(), do: Application.get_env(:ai_devs, :base_url)
  defp questions_url(), do: base_url() <> "/data/" <> api_key() <> "/arxiv.txt"
end
