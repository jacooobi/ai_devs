defmodule Lessons.S02E04.Setup do
  def perform() do
    {:ok, processed_input} = process_input()
    {:ok, _files} = store(processed_input)
  end

  def done?(), do: File.dir?(processed_input_path())

  def process_input() do
    path = input_path()

    path
    |> File.ls!()
    |> Enum.map(fn file ->
      file_path = Path.join([path, file])
      [_ | [extension]] = file |> String.split(".")

      {:ok, processed_file} = process(file_path, extension)

      {output_path(file), processed_file}
    end)
    |> then(&{:ok, &1})
  end

  def store(processed_files) do
    processed_files
    |> Enum.map(fn {path, contents} ->
      File.write!(path, contents)

      path
    end)
    |> then(fn paths -> {:ok, paths} end)
  end

  defp process(file_path, "mp3"),
    do: file_path |> transcribe() |> then(fn {:ok, data} -> translate(data) end)

  defp process(file_path, "png"), do: run_ocr(file_path)
  defp process(file_path, _), do: File.read(file_path)

  def run_ocr(file_path) do
    image_encoded = file_path |> File.read!() |> Base.encode64()

    instructions =
      """
      Extract information from the attached image. Focus on the main block of text, which contains a note.
      Do not output anything besides the text found within the image.
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

  def transcribe(file_path), do: Utils.OpenAI.transcriptions(file_path)

  def translate(text) do
    instructions =
      """
      Translate the following text into polish.
      Be as precise as possible to retain the original meaning.
      """

    Utils.OpenAI.responses(text, instructions: instructions, model: "gpt-4.1")
  end

  def input_path(), do: Path.join(File.cwd!(), input_files_directory())
  def processed_input_path(), do: Path.join(File.cwd!(), processed_files_directory())

  def output_path(file) do
    Path.join(File.cwd!(), [processed_files_directory(), file])
  end

  def input_files_directory(), do: "lib/lessons/s02e04/input/"
  def processed_files_directory(), do: "lib/lessons/s02e04/processed_input/"
end
