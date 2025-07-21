defmodule Lessons.S05E05.Setup do
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

  def index_data() do
    directories = list_directories()

    Enum.map(directories, fn {name, path} ->
      files =
        path
        |> File.ls!()
        |> Enum.map(fn file ->
          {name, file, File.read!(Path.join(path, file))}
        end)

      Enum.map(files, fn {dir, file, content} ->
        content
        |> generate_chunks()
        |> enrich_with_context(content)
        |> generate_embeddings()
        |> create_payloads(dir, file, content)
        |> then(fn cols ->
          Utils.Qdrant.upsert_points(collection_name(), cols)
        end)
      end)
    end)
  end

  def create_collection(name), do: Utils.Qdrant.create_collection(name)
  def remove_collection(name), do: Utils.Qdrant.delete_collection(name)

  def list_directories() do
    [
      {"conversations", "lib/lessons/s05e05/input/conversations"},
      {"factory", "lib/lessons/s05e05/input/factory"},
      {"facts", "lib/lessons/s05e05/input/facts"},
      {"interviews", "lib/lessons/s05e05/input/interviews"},
      {"notes", "lib/lessons/s05e05/input/notes"},
      {"paper", "lib/lessons/s05e05/input/paper"},
      {"reports", "lib/lessons/s05e05/input/reports"},
      {"website", "lib/lessons/s05e05/input/website"}
    ]
  end

  defp collection_name(), do: "s05e05"

  def generate_chunks(text) do
    opts = [chunk_size: 250, chunk_overlap: 50]

    text
    |> TextChunker.split(opts)
    |> Enum.map(& &1.text)
  end

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

      Please give a short succinct context to situate this chunk within the overall document for the purposes of improving search retrieval of the chunk.
      Answer only with the succinct context and nothing else.
      Use the same language as document and chunk.
      """

    case Utils.OpenAI.responses(input) do
      {:ok, result} -> result <> "\n" <> chunk
      _ -> chunk
    end
  end

  def generate_embeddings(list) do
    payload = Enum.map(list, &%{text: &1})

    {:ok, %{"data" => data}} = Utils.JinaAI.create_embeddings(payload)

    embeddings = Enum.map(data, fn %{"embedding" => embedding} -> embedding end)

    Enum.zip(list, embeddings)
  end

  def create_payloads(list, dir, file, content),
    do:
      Enum.map(list, fn {text, embedding} ->
        create_payload(text, embedding, dir, file, content)
      end)

  def create_payload(chunk, embedding, dir, file, content) do
    metadata = %{
      chunk: chunk,
      file: file,
      directory: dir,
      doc: content
    }

    %{
      "id" => Utils.Qdrant.generate_id(),
      "vector" => embedding,
      "payload" => metadata
    }
  end
end
