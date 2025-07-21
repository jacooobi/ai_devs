defmodule Lessons.S03E01.Setup do
  def perform() do
    {:ok, facts} = load_facts()
    {:ok, facts_overview} = generate_summary(facts)
    :ok = File.write(final_document_path(), facts_overview)
  end

  def done?(), do: File.exists?(final_document_path())

  def load_facts() do
    path = input_path()

    path
    |> File.ls!()
    |> Enum.map(&(input_path() |> Path.join(&1) |> File.read!()))
    |> Enum.join("\n")
    |> then(&{:ok, &1})
  end

  def generate_summary(text) do
    instructions = """
    Na podstawie poniższego tekstu przygotuj syntetyczne, przejrzyste podsumowanie w dwóch częściach:

    OPIS STRUKTUR / LOKACJI – zidentyfikuj i opisz kluczowe miejsca, sektory lub jednostki organizacyjne wymienione w tekście. Dla każdej z nich określ ich przeznaczenie, funkcje, poziom zabezpieczeń i znaczenie strategiczne. Zadbaj o logiczny układ i czytelne nagłówki.

    POSTACIE KLUCZOWE – przedstaw sylwetki głównych bohaterów/bohaterek lub postaci wymienionych w tekście. Uwzględnij ich tło, umiejętności, powiązania, rolę w wydarzeniach oraz aktualny status. Zwróć uwagę na ich unikalne cechy i znaczenie dla opisywanej sytuacji.

    Unikaj dosłownego cytowania oryginalnych fragmentów. Skup się na kluczowych informacjach i zwięzłej, rzeczowej formie. Zachowaj kluczowe informacje które przydadzą się potem do tworzenia tagów. Zastosuj styl raportowy – jasny, spójny, uporządkowany, lekko publicystyczny. Każdą sekcję i podsekcję opatrz tytułem, który oddaje jej charakter lub funkcję.
    """

    Utils.OpenAI.responses(text, instructions: instructions, model: "gpt-4.1")
  end

  defp base_directory(), do: "lib/lessons/s03e01/"
  defp input_directory(), do: base_directory() <> "input/"
  defp output_directory(), do: base_directory() <> "processed_input/"

  defp input_path(), do: Path.join(File.cwd!(), [input_directory(), "facts/"])

  def final_document_path(), do: Path.join(File.cwd!(), [output_directory(), "facts.txt"])
end
