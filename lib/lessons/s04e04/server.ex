defmodule Lessons.S04E04.Server do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  post "/webhook" do
    {:ok, body, _conn} = Plug.Conn.read_body(conn)

    response_payload =
      body
      |> JSON.decode()
      |> then(fn {:ok, %{"instruction" => instruction}} -> handle(instruction) end)
      |> then(fn {:ok, response} -> JSON.encode!(%{"description" => response["description"]}) end)

    send_resp(conn, 200, response_payload)
  end

  match _ do
    send_resp(conn, 404, "Not found")
  end

  def start_link(opts \\ []) do
    port = Keyword.get(opts, :port, 4000)
    ref = Keyword.get(opts, :ref, __MODULE__)
    timeout = :timer.seconds(30)
    opts = [idle_timeout: timeout, request_timeout: timeout]

    Plug.Cowboy.http(__MODULE__, [], port: port, ref: ref, protocol_options: opts)
  end

  def stop(ref \\ __MODULE__), do: Plug.Cowboy.shutdown(ref)

  def handle(input) do
    instructions =
      """
      mam mapę (grid) o wymiarach 4x4. Pola są numerowane następująco:

      0,0 - lewy górny róg
      0,3 - prawy górny róg
      3,0 - lewy dolny róg
      3,3 - prawy dolny róg

      na każdym z pól znajduje się inny obiekt:

      0,0 - pinezka
      0,1 - trawa
      0,2 - drzewo
      0,3 - domki
      1,0 - trawa
      1,1 - wiatrak
      1,2 - trawa
      1,3 - trawa
      2,0 - trawa
      2,1 - trawa
      2,2 - skały
      2,3 - drzewa
      3,0 - skały
      3,1 - skały
      3,2 - auto
      3,3 - jaskinia

      pierwotna pozycja na mapie to 0,0 (górny lewy róg)

      Gdzie znajdę się po wykonaniu następującego manewru?

      Odpowiedz w następującym formacie:

      {
        "_thinking": <tutaj tok myślowy>,
        "position": <nowa pozycja>
        "description": <co znajduje się na nowej pozycji>
      }
      """

    input
    |> Utils.OpenAI.responses(instructions: instructions, model: "gpt-4.1")
    |> then(fn {:ok, res} -> JSON.decode(res) end)
  end

  def api_key(), do: Application.get_env(:ai_devs, :api_key)
end
