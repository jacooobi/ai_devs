defmodule Lessons.S02E05.Setup do
  def perform() do
    {:ok, data} = input_url() |> fetch_document() |> save_document()

    {:ok, parsed} = parse_document(data)
    process_document(parsed)

    generate_final_document()
  end

  def done?(), do: File.exists?(final_document_path())

  defp fetch_document(url) do
    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} -> body
      {:error, error} -> {:error, error}
    end
  end

  defp generate_final_document() do
    audio_mappings = create_mappings(:audio)
    image_mappings = create_mappings(:image)

    mappings = %{"audio" => audio_mappings, "images" => image_mappings}
    replace_media_with_text(mappings)
    convert_to_text()
  end

  def replace_media_with_text(mappings) do
    document = File.read!(main_document_path())

    {:ok, parsed_doc} = Floki.parse_document(document)

    output_path = Path.join(File.cwd!(), [output_directory(), "paper.html"])

    parsed_doc
    |> Floki.traverse_and_update(fn
      {"img", attrs, _children} -> fetch_data(mappings, "images", attrs)
      {"source", attrs, _children} -> fetch_data(mappings, "audio", attrs)
      other -> other
    end)
    |> Floki.raw_html()
    |> then(&File.write(output_path, &1))
  end

  def fetch_data(mappings, type, attrs) do
    value = Enum.find_value(attrs, fn {k, v} -> if k == "src", do: v end)

    [_ | [key]] = String.split(value, "/")

    File.read!(Map.get(mappings[type], key))
  end

  def create_mappings(media_type) do
    config = get_config(media_type)

    input_path = Path.join(File.cwd!(), config[:directory])
    files = File.ls!(input_path)

    Enum.reduce(files, %{}, fn file, acc ->
      path = Path.join(File.cwd!(), config[:transcription_directory])

      audio_transcript =
        path |> Path.join(file) |> String.replace(config[:original_ext], ".txt")

      Map.put(acc, file, audio_transcript)
    end)
  end

  def convert_to_text() do
    output_path = Path.join(File.cwd!(), [output_directory(), "paper.html"])

    doc = File.read!(output_path)

    result = HTML2Text.convert(doc, :infinity)

    File.write!(String.replace(output_path, ".html", ".txt"), result)
  end

  defp parse_document(data), do: Floki.parse_document(data)

  def process_document(doc) do
    retrieve_and_process_media(doc, :audio)
    retrieve_and_process_media(doc, :image)
  end

  def retrieve_and_process_media(data, media_type) do
    config = get_config(media_type)

    data
    |> extract_files(config[:attribute], config[:directory])
    |> Enum.map(fn {media_name, media_path} ->
      {:ok, result} = config[:processor].(media_path)

      output_path =
        Path.join(File.cwd!(), [
          config[:transcription_directory],
          String.replace(media_name, config[:original_ext], ".txt")
        ])

      File.write(output_path, result)
    end)
  end

  def get_config(:audio),
    do: %{
      attribute: ~s([type="audio/mpeg"]),
      directory: audio_directory(),
      transcription_directory: audio_transcription_directory(),
      original_ext: ".mp3",
      processor: &transcribe/1
    }

  def get_config(:image),
    do: %{
      attribute: ~s(figure img),
      directory: image_directory(),
      transcription_directory: image_transcription_directory(),
      original_ext: ".png",
      processor: &describe/1
    }

  defp extract_files(document_tree, attribute, directory) do
    document_tree
    |> Floki.find(attribute)
    |> Floki.attribute("src")
    |> Enum.map(fn path ->
      url = data_url() <> path
      [_ | [name]] = String.split(path, "/")

      {:ok, %{body: body}} = HTTPoison.get(url)

      output_path = Path.join(File.cwd!(), [directory, name])
      File.write!(output_path, body)

      {name, output_path}
    end)
  end

  def transcribe(file_path), do: Utils.OpenAI.transcriptions(file_path)

  def describe(file_path) do
    image_encoded = file_path |> File.read!() |> Base.encode64()

    instructions =
      """
        Opisz zawartość obrazka.
        Uwzględnij kluczowe obiekty. Skup się na przedstawieniu esencji grafiki.
        Opis powinien być kompletny i dokładny ale zwięzły.
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

  defp save_document(page) do
    File.write!(main_document_path(), page)

    {:ok, page}
  end

  defp base_url(), do: Application.get_env(:ai_devs, :base_url)
  defp input_url(), do: base_url() <> "/dane/arxiv-draft.html"
  defp data_url(), do: base_url() <> "/dane/"
  defp main_document_path(), do: Path.join(File.cwd!(), [input_directory(), "paper.html"])

  defp base_directory(), do: "lib/lessons/s02e05/"
  defp input_directory(), do: base_directory() <> "input/"
  defp output_directory(), do: base_directory() <> "processed_input/"
  def final_document_path(), do: Path.join(File.cwd!(), [output_directory(), "paper.txt"])

  def audio_directory(), do: input_directory() <> "audio/"
  def image_directory(), do: input_directory() <> "images/"
  def audio_transcription_directory(), do: input_directory() <> "audio_transcriptions/"
  def image_transcription_directory(), do: input_directory() <> "images_transcriptions/"
end
