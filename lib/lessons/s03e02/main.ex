defmodule Lessons.S03E02.Main do
  alias Lessons.S03E02

  @task "wektory"

  def run() do
    if not S03E02.Setup.done?(), do: S03E02.Setup.perform()

    {:ok, %{"result" => query_result}} = query(get_question())
    {:ok, date} = retrieve_answer(query_result)
    {:ok, answer} = transform(date)
    {:ok, _flag} = Utils.AIDevs.submit(@task, answer)
  end

  def query(question) do
    embedding = generate_embedding(question)

    Utils.Qdrant.search_points(collection_name(), embedding)
  end

  def retrieve_answer(%{"points" => [%{"payload" => %{"date" => date}} | _]}), do: {:ok, date}
  def transform(date), do: {:ok, String.replace(date, "_", "-")}

  defp get_question(),
    do: "W raporcie, z którego dnia znajduje się wzmianka o kradzieży prototypu broni?"

  def generate_embedding(text) do
    text
    |> Utils.JinaAI.create_embedding()
    |> then(fn {:ok, embedding} -> embedding end)
  end

  defp collection_name(), do: "s03e02"
end
