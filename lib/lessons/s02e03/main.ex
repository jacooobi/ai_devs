defmodule Lessons.S02E03.Main do
  @task "robotid"

  def run() do
    {:ok, %{"description" => description}} = fetch_description()
    {:ok, %{"data" => [%{"url" => answer}]}} = generate_image(description)
    {:ok, _flag} = Utils.AIDevs.submit(@task, answer)
  end

  def generate_image(description) do
    instructions =
      """
      Na podstawie zeznań osób obserwujących fabrykę,
      stwórz potencjalną wizualizacje robota, którego tam zauwazono.

      #{description}
      """

    Utils.OpenAI.gen_images(instructions)
  end

  defp fetch_description() do
    url = remote_url()

    url
    |> HTTPoison.get()
    |> then(fn {:ok, %{body: body}} -> JSON.decode(body) end)
  end

  defp api_key(), do: Application.get_env(:ai_devs, :api_key)
  defp base_url(), do: Application.get_env(:ai_devs, :base_url)
  defp remote_url(), do: base_url() <> "/data/" <> api_key() <> "/robotid.json"
end
