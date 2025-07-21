defmodule Lessons.S01E01.Main do
  def run do
    {:ok, parsed_html} = fetch_and_parse_webpage()
    {:ok, question} = find_paragraph_by_id(parsed_html, "human-question")
    {:ok, answer} = retrieve_answer(question)
    {:ok, secret_url} = submit_answer(answer)
    {:ok, _flag} = retrieve_flag(secret_url)
  end

  defp fetch_and_parse_webpage() do
    url = robot_system_url()

    with {:ok, html} <- fetch_html(url),
         {:ok, parsed} <- parse_html(html) do
      {:ok, parsed}
    else
      error -> {:error, error}
    end
  end

  defp find_paragraph_by_id(parsed_html, id) do
    case Floki.find(parsed_html, "p##{id}") do
      [{_, _, children}] ->
        text =
          children
          |> Enum.filter(&is_binary/1)
          |> Enum.map(&String.trim/1)
          |> Enum.join(" ")
          |> String.trim()

        {:ok, text}

      _ ->
        {:error, :not_found}
    end
  end

  defp fetch_html(url) do
    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} -> {:ok, body}
      {:error, error} -> {:error, error}
    end
  end

  defp parse_html(html) do
    case Floki.parse_document(html) do
      {:ok, parsed} -> {:ok, parsed}
      {:error, reason} -> {:error, reason}
    end
  end

  def retrieve_answer(question) do
    instructions =
      """
      You are a helpful assistant that provides concise answers.
      For any question, your will only provide the year which is also the answer to the question.
      """

    Utils.OpenAI.responses(question, instructions: instructions)
  end

  def submit_answer(answer) do
    url = robot_system_url()

    body =
      URI.encode_query(%{
        "username" => robot_system_username(),
        "password" => robot_system_password(),
        "answer" => answer
      })

    headers = [
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    case HTTPoison.post(url, body, headers) do
      {:ok, %{status_code: 302, headers: headers}} ->
        headers
        |> Enum.find_value(fn {key, value} -> if key == "Location", do: value, else: nil end)
        |> then(&{:ok, &1})

      {:error, error} ->
        {:error, error}
    end
  end

  def retrieve_flag(url) do
    case HTTPoison.get(robot_system_url() <> url) do
      {:ok, %{status_code: 200, body: body}} ->
        ~r/{{FLG:[^}]+}}/
        |> Regex.run(body)
        |> then(fn [flag] -> {:ok, flag} end)

      {:error, error} ->
        {:error, error}
    end
  end

  defp robot_system_url(), do: Application.get_env(:ai_devs, :s01e01_robot_system_url)
  defp robot_system_username(), do: Application.get_env(:ai_devs, :s01e01_robot_system_username)
  defp robot_system_password(), do: Application.get_env(:ai_devs, :s01e01_robot_system_password)
end
