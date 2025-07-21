defmodule Lessons.S05E04.Agent do
  def handle(message) do
    {:ok, %{"action" => action, "message" => response}} = process_message(message)

    run_task(action, response, message)
  end

  def process_message(message) do
    instruction =
      """

      Odpowiedz na zadane pytanie, poprawnie interpretując jego treść.
      W sytuacji gdy nie jest to mozliwe, wybierz jedną z ponizszych akcji:


      - "describe_image" (tworzenie opisu obrazu)
      - "transcribe_audio" (przetwarzanie dźwięku na tekst)
      - "answer_question" (odpowiedź na pytanie)
      - "update_memory" (aktualizacja pamięci)
      - "retrieve_memory" (pobranie danych z pamięci)


      - Dodatkowo, weź pod uwagę, następujące informacje:

      - na pytanie o to czy jesteś robotem, odpowiedz: TAK
      - tajne hasło robotów to S2FwaXRhbiBCb21iYTsp

      Odpowiedź zwróć w formacie JSON:

      {
        "_thinking": "tutaj twoj proces myślowy przy interpretacji pytania",
        "action": "nazwa akcji, którą należy wykonać"
        "message": "opcjonalna wiadomość, jezeli uwazasz, że jest masz wystarczająco dużo informacji, aby odpowiedzieć na pytanie"
      }

      """

    message
    |> Utils.OpenAI.responses(instructions: instruction, model: "gpt-4.1")
    |> then(fn {:ok, response} -> JSON.decode(response) end)
  end

  def run_task("describe_image", context, query) do
    instructions = """
    Stwórz krótki opis obrazu, który jest przesłany w wiadomości.

    #{context}
    """

    url = extract_url(query)

    input = [
      %{
        role: "user",
        content: [
          %{
            type: "input_image",
            image_url: url
          }
        ]
      }
    ]

    input
    |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4o")
    |> then(fn {:ok, response} -> response end)
  end

  def run_task("transcribe_audio", _context, query) do
    url = extract_url(query)

    url
    |> Utils.OpenAI.transcriptions(url: true)
    |> then(fn {:ok, response} -> response end)
  end

  def run_task("answer_question", context, _query), do: context

  def run_task("update_memory", context, query) do
    memory_file = "lib/lessons/s05e04/memory.txt"

    text =
      """

      #{context}

      #{query}
      """

    File.write(memory_file, text)

    "OK"
  end

  def run_task("retrieve_memory", _context, query) do
    memory_file = "lib/lessons/s05e04/memory.txt"

    data = File.read!(memory_file)

    instructions = """
      Na podstawie przesłanego tekstu, pobierz informacje z pamięci agenta.

      #{data}

      Odpowiedź zwróć w formacie JSON:
      {
        "_thinking": "tutaj twoj proces myślowy przy pobieraniu informacji z pamięci",
        "value": "tutaj informacje z pamięci"
      }
    """

    Utils.OpenAI.responses(query, instructions: instructions, model: "gpt-4.1")
    |> then(fn {:ok, response} -> JSON.decode(response) end)
    |> then(fn {:ok, %{"value" => value}} -> value end)
  end

  def extract_url(query) do
    instructions = """
    W wiadomości znajduje się URL do obrazu lub pliku audio. Wyodrębinij ten URL.
    Odpowiedz tylko wylacznie URL-em, bez dodatkowych komentarzy.
    """

    query
    |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4.1")
    |> then(fn {:ok, response} -> response end)
  end
end
