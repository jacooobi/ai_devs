defmodule Lessons.S04E04.Main do
  @task "webhook"

  def run() do
    start_server()

    {:ok, %{body: body}} = initiate()

    stop_server()

    {:ok, _flag} = retrieve_flag(body)
  end

  def start_server(), do: Lessons.S04E04.Server.start_link()
  def stop_server(), do: Lessons.S04E04.Server.stop()

  def initiate() do
    url = report_url()

    payload =
      JSON.encode!(%{
        "task" => @task,
        "apikey" => api_key(),
        "answer" => public_endpoint()
      })

    headers = [{"Content-Type", "application/json"}]
    timeout = :timer.seconds(60)

    HTTPoison.post(url, payload, headers, timeout: timeout, recv_timeout: timeout)
  end

  def retrieve_flag(response) do
    response
    |> JSON.decode()
    |> then(fn {:ok, %{"message" => message}} -> {:ok, message} end)
  end

  def api_key(), do: Application.get_env(:ai_devs, :api_key)
  def report_url(), do: Application.get_env(:ai_devs, :base_url) <> "/report"
  def public_endpoint(), do: Application.get_env(:ai_devs, :public_endpoint) <> "/webhook"
end
