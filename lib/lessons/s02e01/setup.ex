defmodule Lessons.S02E01.Setup do
  def perform() do
    create_transcriptions()
    combine_txt_files()
  end

  def done?(), do: File.exists?(final_document_path())

  defp create_transcriptions() do
    input_path = input_directory()
    output_path = output_directory()

    input_path
    |> File.ls!()
    |> Enum.sort()
    |> Enum.each(fn file ->
      file_path = Path.join(File.cwd!(), [input_path, file])
      {:ok, transcription} = Utils.OpenAI.transcriptions(file_path)

      File.write!(Path.join(output_path, "#{Path.rootname(file)}.txt"), transcription)
    end)
  end

  defp combine_txt_files() do
    path = output_directory()
    output_path = final_document_path()

    path
    |> File.ls!()
    |> Enum.sort()
    |> Enum.map(fn file -> path |> Path.join(file) |> File.read!() end)
    |> Enum.join("\n")
    |> then(&File.write!(output_path, &1))
  end

  defp base_directory(), do: "lib/lessons/s02e01/"
  defp input_directory(), do: base_directory() <> "input/"
  defp output_directory(), do: base_directory() <> "processed_input/"

  def final_document_path(), do: Path.join(File.cwd!(), [output_directory(), "note.txt"])
end
