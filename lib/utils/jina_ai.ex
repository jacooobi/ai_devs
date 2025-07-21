defmodule Utils.JinaAI do
  def create_embeddings(input) do
    headers = [
      {"Authorization", "Bearer #{api_key()}"},
      {"Content-Type", "application/json"}
    ]

    body =
      JSON.encode!(%{
        "model" => "jina-embeddings-v3",
        "task" => "text-matching",
        "input" => input
      })

    timeout = :timer.seconds(30)

    case HTTPoison.post(api_url() <> "/embeddings", body, headers,
           timeout: timeout,
           recv_timeout: timeout
         ) do
      {:ok, %{status_code: 200, body: response_body}} -> JSON.decode(response_body)
      {_, error} -> {:error, error}
    end
  end

  def create_embedding(input) do
    headers = [
      {"Authorization", "Bearer #{api_key()}"},
      {"Content-Type", "application/json"}
    ]

    body =
      JSON.encode!(%{
        "model" => "jina-embeddings-v3",
        "task" => "text-matching",
        "input" => input
      })

    case HTTPoison.post(api_url() <> "/embeddings", body, headers) do
      {:ok, %{status_code: 200, body: response_body}} ->
        case JSON.decode(response_body) do
          {:ok, %{"data" => [%{"embedding" => embedding} | _]}} ->
            {:ok, embedding}

          {_, error} ->
            {:error, error}
        end

      {_, error} ->
        {:error, error}
    end
  end

  defp api_url(), do: Application.get_env(:ai_devs, :jina_ai_url)
  defp api_key(), do: Application.get_env(:ai_devs, :jina_ai_api_key)
end
