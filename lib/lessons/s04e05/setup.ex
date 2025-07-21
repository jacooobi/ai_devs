defmodule Lessons.S04E05.Setup do
  def perform() do
    split_pdf_into_images()
    process_images()
    combine_txt_files()
  end

  def done?(), do: File.exists?(final_document_path())

  defp split_pdf_into_images() do
    System.cmd("pdftoppm", [input_document_path(), "-png", "-gray", images_path()])
  end

  defp process_images do
    path = images_directory()

    path
    |> File.ls!()
    |> Enum.sort()
    |> Enum.map(fn file ->
      {:ok, text} = retrieve_text_from_image(Path.join(path, file))

      filename = (file |> String.split(".") |> hd) <> ".txt"

      File.write!(Path.join(texts_directory(), filename), text)
    end)
  end

  defp retrieve_text_from_image(file_path) do
    image_encoded = file_path |> File.read!() |> Base.encode64()

    instructions =
      """
      Rozczytaj tekst z obrazka, nie pomijając żadnej litery.
      Nie dodawaj zadnych słów od siebie, zwróć jedynie tekst z obrazka.

      Niektóre obrazki składają się z kilku fragmentów, w takiej sytuacji sprobuj odczytać je osobno a następnie połącz w całość, tak aby wypowiedź miała sens.
      Dodatkowo, w przypadku gdy obrazek zawiera informacje o miejscowościach, załóż że chodzi o miejscowości w Polsce. Możliwe, że nazwy odnoszą się do Grudziądza albo Krakowa.
      """

    input = [
      %{
        role: "user",
        content: [
          %{type: "input_image", image_url: "data:image/jpeg;base64,#{image_encoded}"}
        ]
      }
    ]

    Utils.OpenAI.responses(input, instructions: instructions, model: "gpt-4o")
  end

  defp combine_txt_files() do
    path = texts_directory()
    output_path = final_document_path()

    path
    |> File.ls!()
    |> Enum.sort()
    |> Enum.map(fn file -> path |> Path.join(file) |> File.read!() end)
    |> Enum.join("\n")
    |> then(&File.write!(output_path, &1))
  end

  defp base_directory(), do: "lib/lessons/s04e05/"
  defp input_directory(), do: base_directory() <> "input/"
  defp output_directory(), do: base_directory() <> "processed_input/"
  defp images_directory(), do: output_directory() <> "images/"
  defp texts_directory(), do: output_directory() <> "texts/"

  defp input_document_path(),
    do: Path.join(File.cwd!(), [input_directory(), "notatnik-rafala.pdf"])

  defp images_path(), do: Path.join(File.cwd!(), [output_directory(), "images/page"])

  def final_document_path(), do: Path.join(File.cwd!(), [output_directory(), "pages.txt"])
end
