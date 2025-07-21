defmodule Lessons.S03E03.Main do
  @task "database"

  def run() do
    {:ok, database_structure} = get_structures()
    {:ok, sql_query} = get_sql_query(database_structure, default_question())
    {:ok, results} = retrieve_data(sql_query)

    answer = prepare_for_submission(results)

    {:ok, _flag} = Utils.AIDevs.submit(@task, answer)
  end

  def default_question(),
    do:
      "Your task is to return the IDs of active data centers that are managed by managers who are currently on vacation (inactive)."

  def get_sql_query(context, question) do
    instructions = """
      Given the following insights about the schema:

      #{context}

      Provide me with an SQL code, which answers the query.
      The SQL code should only reference tables and columns from shared database insights.
      You are to return only a valid SQL code snippet as plain text.
      Do not include any markdown formatting (such as triple backticks or syntax labels), comments, or explanations.
      Output the SQL code only and nothing else.
    """

    Utils.OpenAI.responses(question, instructions: instructions, model: "gpt-4.1")
  end

  def get_structures() do
    tables = ["users", "datacenters", "connections"]

    Enum.map(tables, fn table ->
      table
      |> then(fn table -> apidb_service("show create table #{table};") end)
      |> then(fn {:ok, %{"reply" => [%{"Create Table" => sql}]}} -> sql end)
      |> then(fn sql -> String.split(sql, " ENGINE") end)
      |> then(fn [structure, _] -> structure end)
    end)
    |> Enum.join("\n")
    |> then(&{:ok, &1})
  end

  def retrieve_data(query) do
    query
    |> apidb_service()
    |> then(fn {:ok, %{"reply" => replies}} -> {:ok, replies} end)
  end

  def prepare_for_submission(results), do: Enum.flat_map(results, &Map.values(&1))

  def apidb_service(query) do
    url = apidb_url()

    payload =
      JSON.encode!(%{
        task: "database",
        apikey: api_key(),
        query: query
      })

    headers = [{"Content-Type", "application/json"}]

    url
    |> HTTPoison.post(payload, headers)
    |> then(fn {:ok, %{body: body}} -> {:ok, JSON.decode!(body)} end)
  end

  def api_key(), do: Application.get_env(:ai_devs, :api_key)
  def base_url(), do: Application.get_env(:ai_devs, :base_url)
  def apidb_url(), do: base_url() <> "/apidb"
end
