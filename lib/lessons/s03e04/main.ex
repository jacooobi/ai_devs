defmodule Lessons.S03E04.Main do
  @task "loop"

  def run do
    initial_map = retrieve_initial_lists()

    {:ok, place} = scan(initial_map)
    {:ok, _flag} = Utils.AIDevs.submit(@task, place)
  end

  def scan([{"people", []}, {"places", []}]), do: nil

  def scan([{"people", [person | remaining_people]}, {"places", places_list}]) do
    places =
      "people"
      |> api_service(person)
      |> parse_api_response()

    scan([{"people", remaining_people}, {"places", Enum.uniq(places_list ++ places)}])
  end

  def scan([{"people", people_list}, {"places", [place | remaining_places]}]) do
    people =
      "places"
      |> api_service(place)
      |> parse_api_response()

    if Enum.member?(people, "BARBARA") and place != "KRAKOW" do
      {:ok, place}
    else
      scan([{"people", Enum.uniq(people_list ++ people)}, {"places", remaining_places}])
    end
  end

  def retrieve_initial_lists() do
    {:ok, %{body: body}} = HTTPoison.get(input_url())
    body |> get_initial_lists() |> Enum.to_list()
  end

  def get_initial_lists(document) do
    instructions =
      """
      Based on the input text I will provide, extract and return only the following two lists in a JSON format:
        1.	A list of unique place (city) names mentioned in the text, with all Polish characters (e.g., “ł”, “ó”, “ń”) replaced by their non-accented equivalents (e.g., “l”, “o”, “n”).
        2.	A list of unique first names of all individuals explicitly mentioned in the text.

        The output should be a valid JSON object with the structure:

        {
          "places": [ ... ],
          "people": [ ... ]
        }

        Make sure to capitalise every letter for each place and person.
        Do not output anything beyond the JSON object—no explanations, summaries, or formatting.

      """

    document
    |> Utils.OpenAI.responses(
      instructions: instructions,
      model: "gpt-4.1"
    )
    |> then(fn {:ok, response} -> JSON.decode!(response) end)
  end

  def api_service(name, query) when name in ["places", "people"] do
    url = base_url() <> "/#{name}"
    body = JSON.encode!(%{apikey: api_key(), query: query})

    headers = [
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.post(url, body, headers) do
      {:ok, %{body: body}} -> JSON.decode(body)
      {_, error} -> {:error, error}
    end
  end

  defp parse_api_response(response) do
    case response do
      {:ok, %{"message" => "[**RESTRICTED DATA**]"}} ->
        []

      {:ok, %{"message" => message}} ->
        message
        |> String.split(" ")
        |> Enum.map(&Utils.CharacterNormalizer.normalize/1)
        |> Enum.map(&String.upcase/1)

      _ ->
        []
    end
  end

  defp api_key(), do: Application.get_env(:ai_devs, :api_key)
  defp base_url(), do: Application.get_env(:ai_devs, :base_url)

  defp input_url(), do: base_url() <> "/dane/" <> "barbara.txt"
end
