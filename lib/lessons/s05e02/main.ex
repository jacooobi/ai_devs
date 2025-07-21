defmodule Lessons.S05E02.Main do
  @task "gps"

  def run() do
    {:ok, %{"question" => question}} = fetch_questions()
    {:ok, %{"people" => people, "places" => places}} = process_questions(question)

    final_list =
      (people ++ retrieve_users(places))
      |> Enum.uniq()
      |> Enum.reject(&(String.downcase(&1) == "barbara"))
      |> Enum.reject(&(&1 == "Rafał"))

    users_with_ids = retrieve_ids(final_list)

    answer =
      users_with_ids
      |> Enum.reduce(%{}, fn {id, user}, acc ->
        location = locate_user(id)
        Map.put(acc, user, location)
      end)

    Utils.AIDevs.submit(@task, answer)
  end

  def retrieve_ids(users) do
    Enum.map(users, fn user ->
      HTTPoison.post(
        apidb_url(),
        JSON.encode!(%{
          apikey: api_key(),
          task: "database",
          query: "select id from users where username = '#{user}';"
        })
      )
      |> then(fn {:ok, %{body: body}} -> JSON.decode(body) end)
      |> then(fn {:ok, %{"reply" => [%{"id" => id}]}} -> {id, user} end)
    end)
  end

  def retrieve_users(places) do
    places
    |> Enum.map(fn place ->
      payload = JSON.encode!(%{apikey: api_key(), query: place})

      places_url()
      |> HTTPoison.post(payload)
      |> then(fn {:ok, %{body: body}} -> JSON.decode(body) end)
      |> then(fn {:ok, %{"message" => message}} -> String.split(message, " ") end)
    end)
    |> List.flatten()
    |> Enum.uniq()
  end

  def fetch_questions(), do: questions_url() |> fetch() |> Utils.Encoding.fix()

  def fetch(url) do
    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} -> JSON.decode!(body)
      {:error, error} -> {:error, error}
    end
  end

  def analyse(list) do
    instructions = """
    Na podstawie przesłanej listy z elementami ocen czy dotycza osoby czy miejsca

    Odpowiedź zwróć w poprawnym formacie JSON:

    {
      "_thinking": "tutaj twoj proces myślowy przy wyodrebnianiu informacji",
      answer: [
        {
          "name": <nazwa>,
          "type": <typ: osoba/miejsce>
        },
        ...
      ]
    }
    """

    list
    |> Enum.join(", ")
    |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4.1")
    |> then(fn {:ok, response} -> JSON.decode(response) end)
  end

  def process_questions(question) do
    instructions = """
    Na podstawie przesłanego tekstu, wydobądź dwie listy zawierające wymienione w tekscie osoby i nazwy miejsc (miast).

    Odpowiedź zwróć w poprawnym formacie JSON:

    {
      "_thinking": "tutaj twoj proces myślowy przy wyodrebnianiu informacji",
      "people": <lista imion>>
      "places": <lista miejsc>
    }
    """

    question
    |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4.1")
    |> then(fn {:ok, response} -> JSON.decode(response) end)
  end

  def locate_user(id) do
    params = JSON.encode!(%{"userID" => id})

    case HTTPoison.post(gps_url(), params) do
      {:ok, %{body: body}} ->
        JSON.decode!(body) |> Map.get("message")

      {:error, error} ->
        {:error, error}
    end
  end

  defp api_key(), do: Application.get_env(:ai_devs, :api_key)
  defp base_url(), do: Application.get_env(:ai_devs, :base_url)
  defp gps_url(), do: base_url() <> "/gps"
  defp places_url(), do: base_url() <> "/places"
  defp apidb_url(), do: base_url() <> "/apidb"

  defp questions_url(), do: base_url() <> "/data/" <> api_key() <> "/gps_question.json"
end
