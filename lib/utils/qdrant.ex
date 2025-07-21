defmodule Utils.Qdrant do
  def create_collection(
        collection_name,
        vector_size \\ 1024,
        distance \\ "Cosine",
        on_disk_payload \\ true
      ) do
    url = "#{api_url()}/collections/#{collection_name}"

    body =
      JSON.encode!(%{
        "vectors" => %{
          "size" => vector_size,
          "distance" => distance
        },
        "on_disk_payload" => on_disk_payload
      })

    headers = [
      {"Content-Type", "application/json"},
      {"api-key", api_key()}
    ]

    case HTTPoison.put(url, body, headers) do
      {:ok, %{status_code: 200, body: response_body}} ->
        JSON.decode(response_body)

      {:ok, %{status_code: status, body: body}} ->
        {:error, "API request failed with status #{status}: #{body}"}

      {:error, %{reason: reason}} ->
        {:error, "Request failed: #{reason}"}
    end
  end

  def upsert_points(collection_name, points) do
    url = "#{api_url()}/collections/#{collection_name}/points"

    body =
      JSON.encode!(%{
        "points" => points,
        "wait" => true
      })

    headers = [
      {"Content-Type", "application/json"},
      {"api-key", api_key()}
    ]

    case HTTPoison.put(url, body, headers) do
      {:ok, %{status_code: 200, body: response_body}} ->
        JSON.decode(response_body)

      {:ok, %{status_code: status, body: body}} ->
        {:error, "API request failed with status #{status}: #{body}"}

      {:error, %{reason: reason}} ->
        {:error, "Request failed: #{reason}"}
    end
  end

  def search_points(
        collection_name,
        query_vector,
        limit \\ 1,
        score_threshold \\ 0.0,
        filter \\ nil
      ) do
    url = "#{api_url()}/collections/#{collection_name}/points/query"

    body = %{
      "query" => query_vector,
      "limit" => limit,
      "score_threshold" => score_threshold,
      "with_payload" => true
    }

    body = if filter, do: Map.put(body, "filter", filter), else: body
    body = JSON.encode!(body)

    headers = [
      {"Content-Type", "application/json"},
      {"api-key", api_key()}
    ]

    case HTTPoison.post(url, body, headers) do
      {:ok, %{status_code: 200, body: response_body}} ->
        JSON.decode(response_body)

      {:ok, %{status_code: status, body: body}} ->
        {:error, "API request failed with status #{status}: #{body}"}

      {:error, %{reason: reason}} ->
        {:error, "Request failed: #{reason}"}
    end
  end

  def generate_id do
    UUID.uuid4()
  end

  def delete_collection(collection_name) do
    url = "#{api_url()}/collections/#{collection_name}"

    headers = [
      {"Content-Type", "application/json"},
      {"api-key", api_key()}
    ]

    case HTTPoison.delete(url, headers) do
      {:ok, %{status_code: 200, body: response_body}} ->
        JSON.decode(response_body)

      {:ok, %{status_code: status, body: body}} ->
        {:error, "API request failed with status #{status}: #{body}"}

      {:error, %{reason: reason}} ->
        {:error, "Request failed: #{reason}"}
    end
  end

  def get_collection_info(collection_name) do
    url = "#{api_url()}/collections/#{collection_name}"

    headers = [
      {"Content-Type", "application/json"},
      {"api-key", api_key()}
    ]

    case HTTPoison.get(url, headers) do
      {:ok, %{status_code: 200, body: response_body}} ->
        JSON.decode(response_body)

      {:ok, %{status_code: status, body: body}} ->
        {:error, "API request failed with status #{status}: #{body}"}

      {:error, %{reason: reason}} ->
        {:error, "Request failed: #{reason}"}
    end
  end

  defp api_url(), do: Application.get_env(:ai_devs, :qdrant_url)
  defp api_key(), do: Application.get_env(:ai_devs, :qdrant_api_key)
end
