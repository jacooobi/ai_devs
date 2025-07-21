defmodule Utils.OpenAI do
  alias OpenaiEx.Responses
  alias OpenaiEx.Images
  alias OpenaiEx.Audio

  def responses(input, opts \\ []) do
    openai = get_openai()

    request_body = %{
      input: input,
      instructions: opts[:instructions],
      model: opts[:model] || "gpt-4.1-mini"
    }

    case Responses.create(openai, request_body) do
      {:ok, %{"output" => [%{"content" => [%{"text" => text}]} | _]}} -> {:ok, text}
      error -> {:error, error}
    end
  end

  def gen_images(input, opts \\ []) do
    img_request =
      Images.Generate.new(
        prompt: input,
        n: opts[:n] || 1,
        model: opts[:model] || "dall-e-3",
        size: opts[:size] || "1024x1024"
      )

    case Images.generate(get_openai(), img_request) do
      {:ok, img_response} -> {:ok, img_response}
      {_, error} -> {:error, error}
    end
  end

  def transcriptions(path_or_url, opts \\ []) do
    file =
      if opts[:url],
        do: OpenaiEx.new_file(name: path_or_url, content: fetch_blob(path_or_url)),
        else: OpenaiEx.new_file(path: path_or_url)

    transcription_request =
      Audio.Transcription.new(
        file: file,
        model: opts[:model] || "whisper-1"
      )

    case Audio.Transcription.create(get_openai(), transcription_request) do
      {:ok, %{"text" => text}} -> {:ok, text}
      {_, error} -> {:error, error}
    end
  end

  def get_openai(),
    do: openai_api_key() |> OpenaiEx.new() |> OpenaiEx.with_receive_timeout(45_000)

  defp openai_api_key(), do: Application.get_env(:ai_devs, :openai_api_key)

  defp fetch_blob(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{body: body}} ->
        body

      {:error, %HTTPoison.Error{reason: reason}} ->
        raise "Failed to fetch blob: #{inspect(reason)}"
    end
  end
end
