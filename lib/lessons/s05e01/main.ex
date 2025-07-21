defmodule Lessons.S05E01.Main do
  @task "phone"

  def run() do
    if not Lessons.S05E01.Setup.done?(), do: Lessons.S04E05.Setup.perform()

    {:ok, summarised_conversations} = File.read(summary_path())
    {:ok, questions} = fetch_questions()

    {:ok, answers} = answer_questions(summarised_conversations, questions)
    {:ok, _flag} = Utils.AIDevs.submit(@task, answers)
  end

  def load_facts(), do: File.read("lib/lessons/s05e01/input/facts.txt")

  def fetch_questions(), do: questions_url() |> fetch() |> Utils.Encoding.fix()

  def answer_questions(conversations, questions) do
    questions
    |> Enum.map(fn {_, q} -> seek_answer(q, conversations) end)
    |> Enum.map(fn {:ok, %{"answer" => answer}} -> answer end)
    |> then(&{:ok, &1})
  end

  def seek_answer(question, context) do
    instructions = """
    Na podstawie ponizszej notatki udziel zwięzłej, krótkiej odpowiedzi na pytania.

    #{context}

    Odpowiedź zwróć w poprawnym formacie JSON:

    {
      "_thinking": "tutaj twoj proces myślowy przy wyodrebnianiu informacji",
      "answer": "tutaj twoja odpowiedź"
    }
    """

    question
    |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4.1")
    |> then(fn {:ok, response} -> JSON.decode(response) end)
  end

  def prepare_for_submission(%{"answers" => answers}), do: {:ok, answers}

  def fetch(url) do
    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} -> JSON.decode!(body)
      {:error, error} -> {:error, error}
    end
  end

  defp api_key(), do: Application.get_env(:ai_devs, :api_key)
  defp base_url(), do: Application.get_env(:ai_devs, :base_url)

  defp summary_path(), do: "lib/lessons/s05e01/processed_input/summary.txt"

  defp questions_url(), do: base_url() <> "/data/" <> api_key() <> "/phone_questions.json"
end
