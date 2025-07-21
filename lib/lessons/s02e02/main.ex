defmodule Lessons.S02E02.Main do
  def run() do
    {:ok, image} = File.read(input_path())
    {:ok, answer} = retrieve_information(image)
    {:ok, _flag} = retrieve_flag(answer)
  end

  defp retrieve_information(image) do
    instructions = """
    Zadanie: analiza fragmentów mapy i identyfikacja miasta.

    Otrzymujesz zestaw czterech fragmentów mapy. Jeden z fragmentów może pochodzić z innego miasta i być błędnie dobrany.

    Na podstawie zdjęcia, rozpoznaj i zidentyfikuj nazw ulic, charakterystycznych obiektów (np. cmentarzy, kościołów, szkół) i układu urbanistycznego.
    Przed podaniem finalnej odpowiedzi upewnij się, ze rozpoznane lokacje na mapie, na pewno znajdują się w mieście, które zamierzasz zwrócić jako odpowiedź.

    Dodatkowa wskazówka - miasto na mapie jest znane ze spichlerzy i twierdz.

    Podaj odpowiedź wyłącznie jako surowy JSON (bez żadnych dodatkowych znaków, formatowania Markdown ani bloków kodu). Nie używaj znaczników json ani — odpowiedź ma być czystym JSON-em. Format odpowiedzi:
    {
      explanation: "<twoj proces myslowy i uzasadnienie odpowiedzi>",
      answer: "<nazwa miasta>"
    }
    """

    input = [
      %{
        role: "user",
        content: [
          %{
            type: "input_image",
            image_url: "data:image/jpeg;base64,#{Base.encode64(image)}"
          }
        ]
      }
    ]

    Utils.OpenAI.responses(input, instructions: instructions, model: "gpt-4o")
  end

  defp input_path() do
    file = "input/image.jpeg"

    Path.join(File.cwd!(), [input_files_directory(), file])
  end

  def input_files_directory(), do: "lib/lessons/s02e02/"

  defp retrieve_flag(text) do
    data = text |> JSON.decode!() |> Map.get("answer")

    {:ok, "{{FLG:#{data}}}"}
  end
end
