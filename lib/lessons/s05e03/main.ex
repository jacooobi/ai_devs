defmodule Lessons.S05E03.Main do
  def run() do
    url = get_url()
    hash = retrieve_hash(url)
    [_challenges, signature, timestamp] = fetch(url, hash)

    answers = solve()
    payload = prepare_payload(signature, timestamp, answers)

    {:ok, response} = submit_answer(payload)
    {:ok, _flag} = fetch_flag(response)
  end

  def fetch_flag(%{body: body}) do
    body
    |> JSON.decode()
    |> then(fn {:ok, %{"message" => message}} -> {:ok, message} end)
  end

  def solve() do
    urls = [lesson_url() <> "/source1", lesson_url() <> "/source0"]

    urls
    |> Enum.map(fn url ->
      Task.async(fn ->
        %{"data" => data, "task" => task} =
          url |> HTTPoison.get!() |> then(fn %{body: body} -> JSON.decode!(body) end)

        get_answers(data, include_context: task != "Odpowiedz na pytania")
      end)
    end)
    |> Task.await_many(:timer.seconds(10))
    |> Enum.concat()
  end

  def fetch(url, hash) do
    url
    |> HTTPoison.post(JSON.encode!(%{sign: hash}))
    |> then(fn {:ok, response} -> JSON.decode(response.body) end)
    |> then(fn {:ok,
                %{
                  "message" => %{
                    "challenges" => challenges,
                    "signature" => signature,
                    "timestamp" => timestamp
                  }
                }} ->
      [challenges, signature, timestamp]
    end)
  end

  def submit_answer(payload) do
    HTTPoison.post(get_url(), payload)
  end

  def prepare_payload(signature, timestamp, answer) do
    JSON.encode!(%{
      "signature" => signature,
      "timestamp" => timestamp,
      "apikey" => api_key(),
      "answer" => answer
    })
  end

  def get_answers(data, opts) do
    additional_context =
      if Keyword.get(opts, :include_context, false), do: File.read!(context_path()), else: ""

    instructions = """
      Answer in a super concise manner on the following questions. Keep order of answers as in the questions.

      Use this context

      #{additional_context}

      Use the following JSON output:

      {
        "a": ["answer1", "answer2"],
      }
    """

    data
    |> Enum.join("\n")
    |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4o-mini")
    |> then(fn {:ok, response} -> JSON.decode(response) end)
    |> then(fn {:ok, %{"a" => answers}} -> answers end)
  end

  def retrieve_hash(url) do
    url
    |> HTTPoison.post(JSON.encode!(%{password: get_password()}))
    |> then(fn {:ok, %{body: body}} -> JSON.decode!(body) end)
    |> then(fn %{"message" => message} -> message end)
  end

  def api_key(), do: Application.get_env(:ai_devs, :api_key)
  def base_url(), do: Application.get_env(:ai_devs, :base_url)

  def lesson_url(), do: Application.get_env(:ai_devs, :s05e03_url)
  def get_url(), do: lesson_url() <> "/b46c3"
  def get_password(), do: Application.get_env(:ai_devs, :s05e03_password)

  def context_path(), do: "lib/lessons/s05e03/input/paper.txt"
end
