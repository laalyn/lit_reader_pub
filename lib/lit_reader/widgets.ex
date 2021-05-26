defmodule LitReader.Widgets do
  import Ecto.Query, warn: false
  alias LitReader.Repo

  alias LitReader.Reads.Read
  alias LitReader.Sources.Source
  alias LitReader.Configs.Config
  alias LitReader.Characters.Character
  alias LitReader.Acts.Act
  alias LitReader.Scenes.Scene
  alias LitReader.Interactions.Interaction
  alias LitReader.Controls.Control
  alias LitReader.Paragraphs.Paragraph
  alias LitReader.Lines.Line
  alias LitReader.Words.Word
  alias LitReader.Widgets.Widget

  def run_widget(user_id, widget_id) do
    # TODO check if user owns widget

    Repo.transaction(fn ->
      Repo.query!("set transaction isolation level repeatable" <> (if user_id !== nil, do: " read"))

      # grab the widget
      widget = Widget
               |> Repo.get!(widget_id)

      if !widget.from_all do
        raise "querying specific time frame not supported yet"
      end

      # TODO extract as labels, dataset, data
      # TODO SEVERE SQL INJECTION !!
      # TODO implement from-to
      # TODO implement real matching (can match multiple, new table ?)

      # anti sql-injection
      case widget.sort do
        "asc" -> "asc"
        "desc" -> "desc"
        nil -> nil
        _ -> raise "invalid sort"
      end

      # TODO implement one-matching
      case widget.action do
        # TODO can just get raw data with plot??
        "plot" ->
          case widget.item do
            "word" ->
              query =
                "select words.value, sum(words.cnt) from reads\n" <>
                "join acts on reads.id = acts.read_id\n" <>
                "join scenes on acts.id = scenes.act_id\n" <>
                "join interactions on scenes.id = interactions.scene_id\n" <>
                "join paragraphs on interactions.id = paragraphs.interaction_id\n" <>
                "join lines on paragraphs.id = lines.paragraph_id\n" <>
                "join words on lines.id = words.line_id\n" <>
                "where reads.id = '#{widget.read_id}'\n" <>
                "group by words.value\n" <>
                "order by #{if widget.sort !== nil, do: "sum #{widget.sort}, "}words.value" <>
                "#{if widget.take !== nil, do: "\nlimit #{widget.take}"}"
              result = query
                       |> Repo.query!

              # {:ok, %{count: result.num_rows, rows: result.rows}}
              {:ok, parse_to_dataset(result.rows, result.columns)}
            "character" ->
              query =
                "select upper(characters.name) as \"name\", count(*) from reads\n" <>
                "join characters on reads.id = characters.read_id\n" <>
                "join acts on reads.id = acts.read_id\n" <>
                "join scenes on acts.id = scenes.act_id\n" <>
                "join interactions on scenes.id = interactions.scene_id and characters.id = interactions.character_id\n" <>
                "where reads.id = '#{widget.read_id}'\n" <>
                "group by upper(characters.name)\n" <>
                "order by #{if widget.sort !== nil, do: "count #{widget.sort}, "}upper(characters.name)" <>
                "#{if widget.take !== nil, do: "\nlimit #{widget.take}"}"
              result = query
                       |> Repo.query!

              # {:ok, %{count: result.num_rows, rows: result.rows}}
              {:ok, parse_to_dataset(result.rows, result.columns)}
          end
        "plot over" ->
          case widget.item do
            # TODO add 'character lines'??
            "word" ->
              granularity = case widget.granularity do
                "act" -> 0
                "scene" -> 1
                "interaction" -> 2
                "paragraph" -> 3
                "line" -> 4
                _ ->
                  raise "invalid granularity"
              end
              query = "
select #{if granularity >= 0, do: "acts.idx as \"Act\", acts.name"} #{if granularity >= 1, do: ", scenes.idx as \"Scene\", scenes.name"} #{if granularity >= 2, do: ", interactions.idx as \"Interaction\", upper(characters.name) as \"name\""} #{if granularity >= 3, do: ", paragraphs.idx as \"Paragraph\""} #{if granularity >= 4, do: ", lines.idx as \"Line\", lines.value"}, words.value as \"dataset\", sum(words.cnt) from reads
join characters on reads.id = characters.read_id
join acts on reads.id = acts.read_id
join scenes on acts.id = scenes.act_id
join interactions on scenes.id = interactions.scene_id and characters.id = interactions.character_id
join paragraphs on interactions.id = paragraphs.interaction_id
join lines on paragraphs.id = lines.paragraph_id
join words on lines.id = words.line_id
#{if widget.match_s === nil do
"
  and words.value in (
    select value from (
      select words.value, sum(words.cnt) from reads
      join acts on reads.id = acts.read_id
      join scenes on acts.id = scenes.act_id
      join interactions on scenes.id = interactions.scene_id
      join paragraphs on interactions.id = paragraphs.interaction_id
      join lines on paragraphs.id = lines.paragraph_id
      join words on lines.id = words.line_id
      where reads.id = '#{widget.read_id}'
      group by words.value
      #{if widget.sort !== nil, do: "order by sum #{widget.sort}, words.value"}
      #{if widget.take !== nil, do: "limit #{widget.take}"}
    ) as sub
  )
"
else
"
  and words.value ilike '#{widget.match_s}'
"
end
}
where reads.id = '#{widget.read_id}'
group by #{if granularity >= 0, do: "acts.idx, acts.name"} #{if granularity >= 1, do: ", scenes.idx, scenes.name"} #{if granularity >= 2, do: ", interactions.idx, upper(characters.name)"} #{if granularity >= 3, do: ", paragraphs.idx"} #{if granularity >= 4, do: ", lines.idx, lines.value"}, words.value
order by #{if granularity >= 0, do: "acts.idx"} #{if granularity >= 1, do: ", scenes.idx"} #{if granularity >= 2, do: ", interactions.idx"} #{if granularity >= 3, do: ", paragraphs.idx"} #{if granularity >= 4, do: ", lines.idx"}, words.value, sum
"
              result = query
                       |> Repo.query!

              {:ok, parse_to_dataset(result.rows, result.columns)}
            "character" ->
              # TODO not allowing dumb queries for now
              # TODO plot by 'lines of character'
              granularity = case widget.granularity do
                "act" -> 0
                "scene" -> 1
                "interaction" -> 2
                _ ->
                  raise "invalid granularity"
              end
              query = "
select #{if granularity >= 0, do: "acts.idx as \"Act\", acts.name"} #{if granularity >= 1, do: ", scenes.idx as \"Scene\", scenes.name"} #{if granularity >= 2, do: ", interactions.idx as \"Interaction\""}, upper(characters.name) as \"dataset\", count(*) from reads
join characters on reads.id = characters.read_id
join acts on reads.id = acts.read_id
join scenes on acts.id = scenes.act_id
join interactions on scenes.id = interactions.scene_id and characters.id = interactions.character_id
where reads.id = '#{widget.read_id}'
#{if widget.match_s === nil do
"
  and upper(characters.name) in (
    select pname from (
      select upper(characters.name) as \"pname\", count(*) from reads
      join characters on reads.id = characters.read_id
      join acts on reads.id = acts.read_id
      join scenes on acts.id = scenes.act_id
      join interactions on scenes.id = interactions.scene_id and characters.id = interactions.character_id
      where reads.id = '#{widget.read_id}'
      group by upper(characters.name)
      #{if widget.sort !== nil, do: "order by count #{widget.sort}, upper(characters.name)"}
      #{if widget.take !== nil, do: "limit #{widget.take}"}
    ) as sub
  )
"
else
"
  and upper(characters.name) ilike '#{widget.match_s}'
"
end}
group by #{if granularity >= 0, do: "acts.idx, acts.name"} #{if granularity >= 1, do: ", scenes.idx, scenes.name"} #{if granularity >= 2, do: ", interactions.idx"}, upper(characters.name)
order by #{if granularity >= 0, do: "acts.idx"} #{if granularity >= 1, do: ", scenes.idx"} #{if granularity >= 2, do: ", interactions.idx"}, upper(characters.name), count
"
              result = query
                       |> Repo.query!

              {:ok, parse_to_dataset(result.rows, result.columns)}
          end
        "list" ->
          case widget.item do
            "word" ->
              query =
                "select words.value, sum(words.cnt) from reads\n" <>
                "join acts on reads.id = acts.read_id\n" <>
                "join scenes on acts.id = scenes.act_id\n" <>
                "join interactions on scenes.id = interactions.scene_id\n" <>
                "join paragraphs on interactions.id = paragraphs.interaction_id\n" <>
                "join lines on paragraphs.id = lines.paragraph_id\n" <>
                "join words on lines.id = words.line_id\n" <>
                "where reads.id = '#{widget.read_id}'\n" <>
                "#{if widget.match_s !== nil, do: "and words.value ilike '#{widget.match_s}'\n"}" <>
                "group by words.value" <>
                "#{if widget.match_i !== nil, do: "\nhaving sum(words.cnt) = #{widget.match_i}"}" <>
                "#{if widget.sort !== nil, do: "\norder by words.value #{widget.sort}"}" <> # order purely by word
                "#{if widget.take !== nil, do: "\nlimit #{widget.take}"}"
              result = query
                       |> Repo.query!

              {:ok, result.rows}
            "character" ->
              query =
                "select upper(characters.name) as \"name\", count(*) from reads\n" <>
                "join characters on reads.id = characters.read_id\n" <>
                "join acts on reads.id = acts.read_id\n" <>
                "join scenes on acts.id = scenes.act_id\n" <>
                "join interactions on scenes.id = interactions.scene_id and characters.id = interactions.character_id\n" <>
                "where reads.id = '#{widget.read_id}'\n" <>
                "#{if widget.match_s !== nil, do: "and upper(characters.name) ilike '#{widget.match_s}'\n"}" <>
                "group by upper(characters.name)" <>
                "#{if widget.match_i !== nil, do: "\nhaving count(*) = #{widget.match_i}"}" <>
                "#{if widget.sort !== nil, do: "\norder by upper(characters.name) #{widget.sort}"}" <>
                "#{if widget.take !== nil, do: "\nlimit #{widget.take}"}"
              result = query
                       |> Repo.query!

              {:ok, result.rows}
          end
      end
    end)
  end

  def get_widget(user_id, widget_id) do
    # TODO add auth
    widget = Widget
             |> Repo.get!(widget_id)

    proc = %{
      name: widget.name,
      item: widget.item,
      granularity: widget.granularity,
    }

    {:ok, proc}
  end

  def list_widgets(user_id, read_id) do
    # TODO validate user owns

    widgets_query = from w in Widget,
                      select: w,
                      where: w.read_id == ^read_id,
                      order_by: w.updated_at # will be reversed anyway
    widgets = widgets_query
            |> Repo.all()

    proc = Enum.reduce(widgets, [], fn (cur, acc) ->
      next = %{
        id: cur.id,
        name: cur.name,
      }
      [next | acc]
    end)

    {:ok, proc}
  end

  def create_widget(user_id, attrs \\ %{}) do
    widget = %Widget{}
             |> Widget.changeset(attrs)
             |> Repo.insert!

    {:ok, widget.id}
  end

  def delete_widget(user_id, widget_id) do
    # TODO really gotta check if user owns widget

    Widget
    |> Repo.get!(widget_id)
    |> Repo.delete!

    {:ok}
  end

  defp parse_to_dataset(rows, columns) do
    # %{"dataset" => [%{x: "label", y: "data"}, ..], ..}
    datasets = Enum.reduce(rows, %{labels: [], datasets: %{}}, fn (cur, acc) ->
      insert = Enum.reduce(cur, %{columns: columns, label: "", dataset: nil, data: nil}, fn (cur1, acc1) ->
        # IO.inspect(acc1.columns)
        acc1 = case hd(acc1.columns) do
          "count" ->
            acc1
            |> Map.put(:data, cur1)
          "sum" ->
            acc1
            |> Map.put(:data, cur1)
          "dataset" ->
            acc1
            |> Map.put(:dataset, cur1)
          "name" ->
            acc1
            |> Map.put(:label, acc1.label <> cur1 <> " ")
          "value" ->
            acc1
            |> Map.put(:label, acc1.label <> cur1 <> " ")
          col ->
            acc1
            |> Map.put(:label, acc1.label <> col <> " " <> Integer.to_string(cur1) <> ". ")
        end
        Map.put(acc1, :columns, tl acc1.columns)
      end)

      insert = Map.put(insert, :label, String.trim(insert.label))

      acc_datasets = if acc.datasets[insert.dataset] === nil do
        acc.datasets
        |> Map.put(insert.dataset, [])
      else
        acc.datasets
      end

      acc_datasets_sub = [%{x: insert.label, y: insert.data} | acc_datasets[insert.dataset]]

      acc_datasets = Map.put(acc_datasets, insert.dataset, acc_datasets_sub)

      acc
      |> Map.put(:labels, [insert.label | acc.labels])
      |> Map.put(:datasets, acc_datasets)
    end)

    Map.put(datasets, :labels,
      datasets.labels
      |> Enum.uniq()
      |> Enum.reverse()
    )
  end
end
