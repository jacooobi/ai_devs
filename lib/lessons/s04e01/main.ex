defmodule Lessons.S04E01.Main do
  @task "photos"

  def run() do
    {:ok, %{"message" => initial_response}} = initiate()

    %{
      "base_url" => base_url,
      "images" => images,
      "operations" => operations
    } = retrieve_information(initial_response)

    {:ok, final_photos} = Enum.map(images, &obtain_final_photo(base_url, &1, operations))

    {:ok, answer} = generate_physical_description(final_photos)
    {:ok, _flag} = Utils.AIDevs.submit(@task, answer)
  end

  def initiate() do
    payload =
      JSON.encode!(%{
        "task" => @task,
        "apikey" => api_key(),
        "answer" => "START"
      })

    system_api_call(report_url(), payload)
  end

  def fix_photo(image, operation) do
    payload =
      JSON.encode!(%{
        "task" => @task,
        "apikey" => api_key(),
        "answer" => "#{operation} #{image}"
      })

    system_api_call(report_url(), payload)
  end

  def obtain_final_photo(base_path, image, operations) do
    case assess_photo(base_path, image) do
      {:ok, "OK"} ->
        base_path <> image

      {:ok, operation} ->
        image
        |> fix_photo(operation)
        |> then(fn {:ok, %{"message" => message}} -> extract_photo(message) end)
        |> then(fn
          {:ok, %{"operation_successful" => true, "image" => img}} ->
            obtain_final_photo(base_path, img, operations)

          {:ok, %{"operation_successful" => false}} ->
            base_path <> image
        end)
    end
  end

  def generate_physical_description(images) do
    instructions =
      """
      Na podstawie załączonego zdjęcia (lub serii zdjęć), wygeneruj szczegółowy rysopis osoby.
      Uwzględnij:
       - płeć
       - wiek (szacunkowy)
       - wzrost (jeśli możliwe)
       - budowę ciała
       - kolor i długość włosów
       - oczy
       - okulary (jeśli nosi)
       - ubiór
       - styl ubierania się
       - charakterystyczne cechy wyglądu (np. tatuaże, znaki szczególne, wyraz twarzy).

      Użyj języka rzeczowego i precyzyjnego.
      """

    input = [
      %{
        role: "user",
        content: Enum.map(images, &%{type: "input_image", image_url: &1})
      }
    ]

    Utils.OpenAI.responses(input, instructions: instructions, model: "gpt-4o")
  end

  def assess_photo(base_path, img) do
    instructions = """
      przeanalizuj obrazek i ustal czy jego stan moze byc poprawiony.
      Dostępne operacje:

      - DARKEN - naprawia przeswietlone zdjecia, takie na których przewazaja jasne/biale barwy
      - BRIGHTEN - rozjaśnia ciemne zdjęcie, na których nie ma wystarczajaco swiatla
      - REPAIR - usuwa ze zdjecia elementy naniesione, maski, cos co zaslania pierwotne zdjecie.

      jezeli tak, podaj tylko i wylacznie nazwe operacji.
      jezeli nie, zwróć 'OK'
    """

    input = [
      %{
        role: "user",
        content: [
          %{type: "input_image", image_url: base_path <> img}
        ]
      }
    ]

    Utils.OpenAI.responses(input, instructions: instructions, model: "gpt-4o")
  end

  def extract_photo(text) do
    instructions = """
    Z wiadomości ustal czy operacji modyfikacji zdjęcia się powiodła. Jezeli tak, wyodrębnij równiez nazwe nowego pliku. Podczas ekstrakcji nazwy pliku, nie podawaj pełnego URL.

    podane informacje zwróć tylko i wylacznie w poprawnym JSONie:

      {
        _thinking: <tutaj twoj proces myslowy przy wyodrebnianiu informacji>,
        operation_successful: true/false
        image: url zdjęcia jezeli obecne
      }
    """

    text
    |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4.1")
    |> then(fn {:ok, response} -> JSON.decode(response) end)
  end

  def retrieve_information(text) do
    instructions = """
      Z wiadomości wyodrębnij kluczowe informacje, takie jak:

      - nazwy plików
      - główny url pod którym dostępne są pliki
      - dostepne operacje na plikach

      podane informacje zwróć tylko i wylacznie w poprawnym JSONie:

      {
        _thinking: <tutaj twoj proces myslowy przy wyodrebnianiu informacji>,
        images: lista images,
        base_url: bazowy url,
        operations: lista operacji
      }
    """

    text
    |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4.1")
    |> then(fn {:ok, response} -> JSON.decode!(response) end)
  end

  def system_api_call(url, payload) do
    url
    |> HTTPoison.post(payload, [{"Content-Type", "application/json"}])
    |> then(fn {:ok, %{body: body}} -> {:ok, JSON.decode!(body)} end)
  end

  def api_key(), do: Application.get_env(:ai_devs, :api_key)
  def report_url(), do: Application.get_env(:ai_devs, :base_url) <> "/report"
end
