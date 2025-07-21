defmodule Lessons.S03E02.Setup do
  def perform() do
    initialize_collection()
    index_data()
  end

  def done? do
    case Utils.Qdrant.get_collection_info(collection_name()) do
      {:ok, %{"result" => result}} -> result["points_count"] > 0
      _ -> false
    end
  end

  def initialize_collection() do
    name = collection_name()

    case Utils.Qdrant.get_collection_info(name) do
      {:ok, _} ->
        remove_collection(name)
        create_collection(name)

      _ ->
        create_collection(name)
    end
  end

  def create_collection(name), do: Utils.Qdrant.create_collection(name)
  def remove_collection(name), do: Utils.Qdrant.delete_collection(name)

  def load_files do
    path = input_path()

    path
    |> File.ls!()
    |> Enum.map(fn file ->
      {file, File.read!(Path.join(path, file))}
    end)
  end

  def index_data() do
    data = load_files()

    Enum.map(data, fn {file, content} ->
      content
      |> generate_chunks()
      |> enrich_with_context(content)
      |> generate_embeddings()
      |> create_payloads(file)
      |> then(fn cols ->
        Utils.Qdrant.upsert_points(collection_name(), cols)
      end)
    end)
  end

  def generate_chunks(text), do: text |> String.split("\n") |> Enum.reject(&(&1 == ""))

  def enrich_with_context(chunks, content), do: Enum.map(chunks, &contextualise(&1, content))

  def contextualise(chunk, content) do
    input =
      """
      <document>
      #{content}
      </document>

      Here is the chunk we want to situate within the whole document

      <chunk>
      #{chunk}
      </chunk>

      Please give a short succinct context to situate this chunk within the overall document for the purposes of improving search retrieval of the chunk. Answer only with the succinct context and nothing else. Use the same language as document and chunk.
      """

    case Utils.OpenAI.responses(input) do
      {:ok, result} -> result <> "\n" <> chunk
      _ -> chunk
    end
  end

  def generate_embeddings(list), do: Enum.map(list, &generate_embedding(&1))

  def generate_embedding(text) do
    text
    |> Utils.JinaAI.create_embedding()
    |> then(fn {:ok, embedding} -> {text, embedding} end)
  end

  def create_payloads(list, file),
    do: Enum.map(list, fn {text, embedding} -> create_payload(embedding, text, file) end)

  def create_payload(embedding, chunk, filename) do
    metadata = %{
      chunk: chunk,
      date: parse_date(filename),
      file: filename
    }

    %{
      "id" => Utils.Qdrant.generate_id(),
      "vector" => embedding,
      "payload" => metadata
    }
  end

  def input_path(), do: Path.join(Path.expand(__DIR__), "input")

  defp parse_date(filename) do
    filename |> String.split(".") |> hd()
  end

  defp collection_name(), do: "s03e02"
end
