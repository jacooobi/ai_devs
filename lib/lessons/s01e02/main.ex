defmodule Lessons.S01E02.Main do
  def run do
    {:ok, %{"msgID" => msg_id, "text" => question}} = initialize_verification()
    {:ok, answer} = retrieve_answer(question)
    {:ok, submission} = submit_verification(msg_id, answer)
    {:ok, _flag} = retrieve_flag(submission)
  end

  def initialize_verification() do
    payload =
      JSON.encode!(%{
        "text" => "READY",
        "msgID" => 0
      })

    verify_url()
    |> HTTPoison.post(payload)
    |> then(fn {:ok, %{body: body}} -> JSON.decode(body) end)
  end

  def submit_verification(msg_id, answer) do
    payload =
      JSON.encode!(%{
        "text" => answer,
        "msgID" => msg_id
      })

    verify_url()
    |> HTTPoison.post(payload)
    |> then(fn {:ok, %{body: body}} -> JSON.decode(body) end)
  end

  defp retrieve_flag(%{"text" => flag}), do: {:ok, flag}

  def retrieve_answer(question) do
    instructions = """
      You are a helpful assistant that provides concise answers.
      For any question, your will provide the answer in English and if possible, in a single word only.
      There are also three questions to which answer is predetermined:
      - capital of Poland is Kraków
      - the well-known number from the book The Hitchhiker's Guide to the Galaxy is 69.
      - current year is 1999
    """

    Utils.OpenAI.responses(question, instructions: instructions, model: "gpt-4.1")
  end

  defp base_url(), do: Application.get_env(:ai_devs, :s01e01_robot_system_url)
  defp verify_url(), do: base_url() <> "/verify"
end
