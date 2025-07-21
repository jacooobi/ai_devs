defmodule Lessons.S04E05.Main do
  @task "notes"

  def run() do
    if not Lessons.S04E05.Setup.done?(), do: Lessons.S04E05.Setup.perform()

    {:ok, context} = fetch_context()
    {:ok, questions} = fetch_questions()

    {:ok, response} = handle_questions(context, fix_encoding(questions))
    {:ok, answer} = prepare_for_submission(response)
    {:ok, _flag} = Utils.AIDevs.submit(@task, answer)
  end

  def fetch_context(), do: File.read(Lessons.S04E05.Setup.final_document_path())

  def fetch_questions() do
    case HTTPoison.get(questions_url()) do
      {:ok, %{status_code: 200, body: body}} -> JSON.decode(body)
      {:error, error} -> {:error, error}
    end
  end

  def fix_encoding(questions) do
    Enum.reduce(questions, %{}, fn {id, question}, acc ->
      Map.put(acc, id, String.replace(question, "\u00A0", " "))
    end)
  end

  def prepare_for_submission(%{"answers" => answers}), do: {:ok, answers}

  def handle_questions(context, questions) do
    input =
      questions
      |> Enum.map(fn {id, question} -> "#{id}: #{question}" end)
      |> Enum.join("\n")

    instructions = """
      Na podstawie ponizszego kontekstu odpowiedz na pytania.

      #{context}

      Odpowiedź koniecznie zwróć w ponizszym formacie JSON

      {
        "_thinking": <tutaj twoj proces myslowy przy wyodrebnianiu informacji>,
        "answers": {
          "01": "odpowiedź na pytanie 01",
          "02": "odpowiedź na pytanie 02",
          "03": "odpowiedź na pytanie 03",
          ...
          "0n": "odpowiedź na pytanie 0n"
        }
      }

      Uwzględnij wszystkie fakty podane w tekście, w szczególności odwołania do wydarzeń. Upewnij się, ze daty sa poprawne, np. chat GPT-2 wyszedl w 2019, nie 2017 czy 2018.
      W przypadku miejsc, takich jak leśna kryjówka, możesz uwzględnić opis tego miejsca, jego szkic, czy tajemnicze namiary koło szkicu.

      Wazne informacje:
      - Rafał przeniósł się do roku 2019.
      - Rafał znalazł schronienie w leśnej grota pod Grudziądzem.
      - Data pewnego waznego spotkania to 2024-11-12.
    """

    input
    |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4.1")
    |> then(fn {:ok, response} -> JSON.decode(response) end)
  end

  def api_key(), do: Application.get_env(:ai_devs, :api_key)
  def base_url(), do: Application.get_env(:ai_devs, :base_url)

  def questions_url, do: base_url() <> "/data/" <> api_key() <> "/notes.json"
end
