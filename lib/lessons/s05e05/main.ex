defmodule Lessons.S05E05.Main do
  @task "story"

  def run() do
    if not Lessons.S05E05.Setup.done?(), do: Lessons.S05E05.Setup.perform()

    {:ok, questions} = fetch_questions()
    {:ok, questions} = process_questions(questions)

    answers = answer_questions(questions)

    Utils.AIDevs.submit(@task, answers)
  end

  def answer_questions(questions) do
    questions
    |> Enum.with_index()
    |> Enum.map(fn {q, idx} -> answer_question(idx, q) end)
  end

  def answer_question(idx, question) do
    IO.puts("Processing question #{idx}: #{question}")

    embedding = generate_embedding(question)

    seek_answer(question, embedding)
  end

  def seek_answer(question, embedding) do
    collection = collection_name()

    collection
    |> Utils.Qdrant.search_points(embedding, 5)
    |> then(fn {:ok, %{"result" => %{"points" => points}}} -> points end)
    |> Enum.map(fn %{"payload" => %{"chunk" => chunk}} -> chunk end)
    |> then(fn chunks -> ask_ai(question, chunks) end)
  end

  def ask_ai(question, chunks) do
    instructions = """
      Spróbuj zwięźle odpowiedzieć na zadanie pytanie wykorzystując ten kontekst.

      Mozliwe, ze nie wszystkie fragmenty będą przydane do odpowiedzi, wykorzystaj tylko te, ktore maja przeslanki do bycia najblizej prawdy

      #{Enum.join(chunks, "\n")}

      podane informacje zwróć tylko i wylacznie w poprawnym JSONie, bez zadnych dodatkowych adnotacji

      {
        "_thinking": "tutaj twoj proces myślowy przy wyodrebnianiu informacji",
        "answer": "krotka odpowiedz na zadane pytanie"
      }
    """

    question
    |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4.1")
    |> then(fn {:ok, res} -> JSON.decode(res) end)
    |> then(fn {:ok, %{"_thinking" => _thinking, "answer" => answer}} -> answer end)
  end

  def generate_embedding(text) do
    text
    |> Utils.JinaAI.create_embedding()
    |> then(fn {:ok, embedding} -> embedding end)
  end

  def fetch_questions() do
    case HTTPoison.get(questions_url()) do
      {:ok, %{status_code: 200, body: body}} -> {:ok, JSON.decode!(body)}
      {:error, error} -> {:error, error}
    end
  end

  def process_questions(questions), do: Utils.Encoding.fix(questions)

  defp collection_name(), do: "s05e05"

  defp api_key(), do: Application.get_env(:ai_devs, :api_key)
  defp base_url(), do: Application.get_env(:ai_devs, :base_url)
  defp questions_url(), do: base_url() <> "/data/" <> api_key() <> "/story.json"
end
