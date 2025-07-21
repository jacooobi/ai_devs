defmodule Lessons.S05E01.Setup do
  def perform() do
    {:ok, conversations} = fetch_conversations()
    {:ok, facts} = load_facts()

    conversations
    |> process(facts)
    |> tap(&save(&1))
    |> summarize(facts)
    |> save_summaries()
  end

  def done?, do: File.exists?(final_document_path())

  def process(conversations, facts) do
    Enum.map(conversations, fn {id, conversation} ->
      IO.puts("Processing conversation #{id}")

      conversation = Enum.join(conversation, "\n")

      {:ok, %{"speakers" => speakers}} = determine_speakers(conversation, facts)
      {:ok, %{"conversation" => updated_conversation}} = assign_speakers(conversation, speakers)

      {id, updated_conversation}
    end)
  end

  def save(conversations) do
    Enum.each(conversations, fn {id, conversation} ->
      File.write!("lib/lessons/s05e01/processed_input/#{id}.txt", Enum.join(conversation, "\n"))
    end)
  end

  def determine_speakers(conversation, context) do
    instructions = """
      W oparciu o zapis konwersacji, zidentyfikuj (nazwij) osoby biorące udział w rozmowie. W rozmowie naprzemiennie wypowiadają się dwie osoby.

      Do identyfikacji osób mozesz posłuzyc się kontekstem, który zawiera informacje o osobach, ich rolach i relacjach.

      #{context}

      Odpowiedź zwróć w formacie JSON:

      {
        "_thinking": "tutaj twoj proces myślowy przy identyfikacji osób",
        "speakers": [
          "<identified speaker 1>",
          "<identified speaker 2>"
        ]
      }
    """

    conversation
    |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4.1")
    |> then(fn {:ok, response} -> JSON.decode(response) end)
  end

  def assign_speakers(conversation, speakers) do
    instructions = """
      Do podanej konwersacji przypisz poprawnie imiona osób które się wypowiadają.

      Imiona osób to: #{Enum.join(speakers, ", ")}

      Wypowiedzi są oddzielone znakiem nowej linii.

      Upewnij sie ze kazda osoba zostala jest poprawnie przypisana! Nie moze byc sytuacji ze osoba zwraca sie do siebie w trzeciej osobie, a nie w pierwszej.
      Szczegolnie zwróc uwagę na przywitania i pożegnania, tak aby przypisana osoba nie zwracała się do samej siebie.

      Odpowiedź zwróć w formacie JSON:

      {
        "_thinking": "tutaj twoj proces myślowy przy identyfikacji osób",
        "conversation": [
          "{identified speaker} : <message 1>",
          "{identified speaker} : <message 2>",
          ...
          "{identified speaker} : <message N>"
        ]
      }
    """

    conversation
    |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4.1")
    |> then(fn {:ok, response} -> JSON.decode(response) end)
  end

  def summarize(conversations, facts) do
    Enum.map(conversations, fn {id, conversation} ->
      instructions = """
        Obszernie podsumuj rozmowę kazdej z osób osobno, uwzględniając kontekst i fakty. Podsumowanie musi zawierać wszystkie kluczowe informacje.

        Dodatkowy kontekst ktory moze byc przydatny do podusmowania: #{facts}

        Odpowiedź zwróć w poniższym formacie:

        Rozmowa #{id}

        <rozmowówca 1>

        <obszerne podsumowanie rozmowy dla tej osoby>

        <rozmowówca 2>

        <obszerne podsumowanie rozmowy dla tej osoby>
      """

      conversation
      |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4.1")
      |> then(fn {:ok, response} -> response end)
    end)
  end

  def save_summaries(summaries) do
    summaries
    |> Enum.join("\n")
    |> then(&File.write(final_document_path(), &1))
  end

  def fetch_conversations(), do: conversations_url() |> fetch() |> Utils.Encoding.fix()

  defp fetch(url) do
    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} -> JSON.decode!(body)
      {:error, error} -> {:error, error}
    end
  end

  defp api_key(), do: Application.get_env(:ai_devs, :api_key)
  defp base_url(), do: Application.get_env(:ai_devs, :base_url)

  defp conversations_url(), do: base_url() <> "/data/" <> api_key() <> "/phone_sorted.json"

  def load_facts(), do: File.read("lib/lessons/s05e01/input/facts.txt")
  def output_directory(), do: File.read("lib/lessons/s05e01/processed_input")
  def final_document_path(), do: "lib/lessons/s05e01/processed_input/summary.txt"
end
