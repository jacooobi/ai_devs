defmodule Lessons.S03E05.Main do
  @task "connections"

  def run() do
    {:ok, conn} = start_graph_db()

    if not Lessons.S03E05.Setup.done?(conn), do: Lessons.S03E05.Setup.perform(conn)

    {:ok, path} = find_shortest_path(conn, "Rafał", "Barbara")
    {:ok, answer} = process_query_result(path)

    :ok = stop_graph_db(conn)

    {:ok, _flag} = Utils.AIDevs.submit(@task, answer)
  end

  def find_shortest_path(conn, from, to) do
    query = shortest_path_query(from, to)

    case Boltx.query(conn, query) do
      {:ok, %{records: [[%{nodes: nodes}]]}} -> {:ok, nodes}
      {_, error} -> {:error, error}
    end
  end

  defp process_query_result(nodes) do
    nodes
    |> Enum.map(fn %{properties: %{"username" => username}} -> username end)
    |> Enum.join(",")
    |> then(&{:ok, &1})
  end

  def shortest_path_query(from, to) do
    """
    MATCH (start:User {username: "#{from}"}), (end:User {username: "#{to}"})
    MATCH path = shortestPath((start)-[:CONNECTED_TO*]-(end))
    RETURN path
    """
  end

  def start_graph_db(), do: Boltx.start_link(connection_opts())
  def stop_graph_db(conn), do: GenServer.stop(conn)

  defp connection_opts() do
    [
      auth: [username: neo4j_user(), password: neo4j_password()],
      user_agent: "boltxTest/1",
      pool_size: 15,
      max_overflow: 3,
      prefix: :default,
      uri: neo4j_url()
    ]
  end

  defp neo4j_url(), do: Application.get_env(:ai_devs, :neo4j_url)
  defp neo4j_user(), do: Application.get_env(:ai_devs, :neo4j_user)
  defp neo4j_password(), do: Application.get_env(:ai_devs, :neo4j_password)
end
