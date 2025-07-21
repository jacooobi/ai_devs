defmodule Lessons.S02E01.Main do
  @task "mp3"

  def run() do
    if not Lessons.S02E01.Setup.done?(), do: Lessons.S02E01.Setup.perform()

    {:ok, context} = fetch_context()
    {:ok, summarised_context} = process_context(context)
    {:ok, answer} = retrieve_information(summarised_context)
    {:ok, _flag} = Utils.AIDevs.submit(@task, answer)
  end

  def fetch_context(), do: File.read(Lessons.S02E01.Setup.final_document_path())

  def process_context(input) do
    instructions = """
      Na podstawie przesłanego tekstu, stwórz obszerną notatkę,
      która skupi się wyłącznie na informacjach o Andrzeju Maju.
    """

    Utils.OpenAI.responses(input, instructions: instructions, model: "gpt-4.1")
  end

  def retrieve_information(context) do
    input = """
      Na jakiej ulicy znajduje się konkretny instytut uczelni, gdzie wykłada profesor Andrzej Maj.
      Odpowiedz tylko i wyłącznie podając konkretnę informacje, nie odpowiadaj pełnym zdaniem.
    """

    Utils.OpenAI.responses(input, instructions: context, model: "gpt-4.1")
  end
end
