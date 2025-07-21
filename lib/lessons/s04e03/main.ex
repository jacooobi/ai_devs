defmodule Lessons.S04E03.Main do
  @task "softo"

  def run() do
    {:ok, questions} = fetch_questions()

    {:ok, answer} = process(questions)

    {:ok, _flag} = Utils.AIDevs.submit(@task, answer)
  end

  def process(questions) do
    questions
    |> Enum.reduce(%{}, fn {id, question}, acc ->
      IO.puts("Processing question #{id}: #{question}")
      Map.put(acc, id, get_answer(question))
    end)
    |> then(&{:ok, &1})
  end

  def get_answer(question) do
    start_url = construct_url("/")
    visited_urls = [start_url]

    seek_answer(question, start_url, [], visited_urls)
  end

  defp construct_url(path) do
    uri = URI.parse(path)

    URI.to_string(%{start_url() | path: uri.path})
  end

  def seek_answer(question, url, to_visit, visited_urls) do
    {:ok, %{body: body}} = HTTPoison.get(url)

    text =
      body
      |> Floki.parse_document!()
      |> Floki.find("body")
      |> Floki.raw_html()
      |> String.replace(~r/<!--.*?-->/s, "")

    new_urls =
      body
      |> Floki.parse_document!()
      |> Floki.find("a")
      |> Floki.attribute("href")
      |> Enum.map(&construct_url/1)
      |> Enum.reject(&Enum.member?(forbidden_urls(), &1))
      |> Enum.reject(&Enum.member?(visited_urls, &1))
      |> Enum.uniq()

    to_visit = (new_urls ++ to_visit) |> Enum.uniq()

    {:ok, %{"result" => result, "answer" => answer}} = answer_available?(question, text)

    if result do
      answer
    else
      {:ok, %{"link" => link}} = link_selector(to_visit, question)
      final_url = construct_url(link)

      seek_answer(question, final_url, to_visit -- [final_url], [
        final_url | visited_urls
      ])
    end
  end

  def answer_available?(question, text) do
    instructions = """
      Wykorzystując ponizszy tekst:

      #{text}

      Ustal czy jest mozliwa znalezienie bezposredniej odpowiedzi na zadane pytanie.
      Odpowiedz w ponizszym formacie JSON:

      {
        "_thinking": "Twoje przemyślenia na temat tego, czy odpowiedź jest dostępna",
        "result": <true or false>
        "answer" : "jeśli odpowiedź jest dostępna, to podaj ją tutaj, w przeciwnym razie pozostaw puste"
      }

    """

    question
    |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4.1")
    |> then(fn {:ok, response} -> JSON.decode(response) end)
  end

  def link_selector(urls, question) do
    instructions = """
      W oparciu o zadane pytanie, dobierz najlepszy link do sprawdzenia, czy jest możliwa odpowiedź na to pytanie.

      Dostępne linki do sprawdzenia:

      #{Enum.join(urls, "\n")}

      Odpowiedz w ponizszym formacie JSON:

      {
        "_thinking": "Twoje przemyślenia na temat tego, czy są linki do sprawdzenia",
        "link": "link do sprawdzenia wobec ktorego masz najwieksze szanse znalezienia odpowiedzi"
      }
    """

    question
    |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4.1")
    |> then(fn {:ok, response} -> JSON.decode(response) end)
  end

  def forbidden_urls do
    Enum.map(["/loop", "/czescizamienne"], &construct_url/1)
  end

  def fetch_questions() do
    questions_url() |> HTTPoison.get() |> then(fn {:ok, %{body: body}} -> JSON.decode(body) end)
  end

  def start_url(), do: URI.parse(Application.get_env(:ai_devs, :base_url))
  def questions_url, do: base_url() <> "/data/" <> api_key() <> "/softo.json"

  def base_url(), do: Application.get_env(:ai_devs, :base_url)
  def api_key(), do: Application.get_env(:ai_devs, :api_key)
end
