defmodule Utils.AIDevs do
  def submit(task, answer) do
    url = report_url()

    payload =
      JSON.encode!(%{
        "task" => task,
        "apikey" => api_key(),
        "answer" => answer
      })

    headers = [{"Content-Type", "application/json"}]

    url
    |> HTTPoison.post(payload, headers)
    |> then(fn
      {:ok, %{body: body}} -> {:ok, body |> JSON.decode!() |> Map.get("message")}
      {_, error} -> {:error, error}
    end)
  end

  defp api_key(), do: Application.get_env(:ai_devs, :api_key)
  defp base_url(), do: Application.get_env(:ai_devs, :base_url)
  defp report_url(), do: base_url() <> "/report"
end
