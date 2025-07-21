defmodule Lessons.S03E05.Setup do
  def perform(conn) do
    [users, connections] = retrieve_data()

    clear_db(conn)
    insert_users(conn, users)
    insert_connections(conn, connections)
  end

  def done?(conn) do
    query = "MATCH (n:User) RETURN count(n) > 0;"

    conn
    |> Boltx.query!(query)
    |> then(fn %{records: [[result]]} -> result end)
  end

  def retrieve_data() do
    users_query = "select * from users"
    connections_query = "select * from connections"

    Enum.map([users_query, connections_query], fn query ->
      query
      |> api_service()
      |> then(fn {:ok, %{"reply" => reply}} -> reply end)
    end)
  end

  def clear_db(conn) do
    query = "MATCH (n) DETACH DELETE n"
    Boltx.query!(conn, query)
  end

  def insert_users(conn, users) do
    Enum.each(users, fn user ->
      query = """
      CREATE (u:User {
        userId: "#{Map.get(user, "id")}",
        username: "#{Map.get(user, "username")}",
        access_level: "#{Map.get(user, "access_level")}",
        is_active: "#{Map.get(user, "is_active")}",
        lastlog: "#{Map.get(user, "lastlog")}"
      })
      """

      Boltx.query!(conn, query)
    end)
  end

  def insert_connections(conn, connections) do
    Enum.each(connections, fn connection ->
      query = """
      MATCH (u1:User {userId: "#{Map.get(connection, "user1_id")}"})
      MATCH (u2:User {userId: "#{Map.get(connection, "user2_id")}"})
      CREATE (u1)-[:CONNECTED_TO]->(u2)
      """

      Boltx.query!(conn, query)
    end)
  end

  def api_service(query) do
    url = api_url() <> "/apidb"

    body =
      JSON.encode!(%{
        task: "database",
        apikey: api_key(),
        query: query
      })

    headers = [
      {"Content-Type", "application/json"}
    ]

    case HTTPoison.post(url, body, headers) do
      {:ok, %{body: body}} -> JSON.decode(body)
      {_, error} -> {:error, error}
    end
  end

  defp api_key(), do: Application.get_env(:ai_devs, :api_key)
  defp api_url(), do: Application.get_env(:ai_devs, :base_url)
end
