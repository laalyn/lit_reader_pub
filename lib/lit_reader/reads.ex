defmodule LitReader.Reads do
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
  alias LitReader.Widgets

  def parse_source(user_id, read_id) do
    # TODO check if user owns the read
    # TODO check read type
    # TODO make parser work with multi-tag headers i.e. Hamlet
    # TODO make this socket
    # TODO autogenerate read name if nil

    Repo.transaction(fn ->
      # will be deleting and inserting new things based off of existing read, so need high isolation
      # read repeatable allows more concurrency than serializable and also works
      Repo.query!("set transaction isolation level repeatable read")

      # grab the source
      source = Source
               |> Repo.get_by!(read_id: read_id)

      # source
      # |> IO.inspect()

      # grab the configs
      get_configs_query = from c in Config,
                            select: c,
                            where: c.read_id == ^read_id
      configs = get_configs_query
      |> Repo.all()

      # configs
      # |> IO.inspect()

      matches = represent_configs(configs)

      # matches
      # |> IO.inspect()

      stops = represent_stops(configs)

      # stops
      # |> IO.inspect()

      # assuming its a play
      # parse and have inserts ready
      nil_char_id = UUID.uuid4()
      result = source.value
               |> Floki.parse_document!
               |> Floki.find("body")
               |> Enum.at(0)
               |> elem(2)
               |> parse_play_imp(matches, stops, nil, %{none: nil_char_id}, %{read_id: read_id, act: %{id: nil, idx: nil}, scene: %{id: nil, idx: nil}, interaction: %{id: nil, idx: nil}, paragraph: %{id: nil, idx: nil}, line_idx: nil}, %{Character => [%{id: nil_char_id, name: "_none", read_id: read_id}], Act => [], Scene => [], Interaction => [], Control => [], Paragraph => [], Line => [], Word => []}, 0)

      # IO.puts("==== FINAL ====")
      # IO.inspect(result.inserts)

      inserts = result.inserts

      # delete everything (cascade delete enabled)
      delete_acts_query = from a in Act,
                            select: a,
                            where: a.read_id == ^read_id
      delete_acts_query
      |> Repo.delete_all()

      delete_characters_query = from c in Character,
                                  select: c,
                                  where: c.read_id == ^read_id
      delete_characters_query
      |> Repo.delete_all()

      # insert
      Repo.insert_all(Character, inserts[Character])
      Repo.insert_all(Act, inserts[Act])
      Repo.insert_all(Scene, inserts[Scene])
      inserts[Interaction]
      |> Enum.chunk_every(16000)
      |> Enum.each(fn (cur) ->
           Repo.insert_all(Interaction, cur)
      end)
      inserts[Control]
      |> Enum.chunk_every(16000)
      |> Enum.each(fn (cur) ->
        Repo.insert_all(Control, cur)
      end)
      inserts[Paragraph]
      |> Enum.chunk_every(16000)
      |> Enum.each(fn (cur) ->
        Repo.insert_all(Paragraph, cur)
      end)
      inserts[Line]
      |> Enum.chunk_every(16000)
      |> Enum.each(fn (cur) ->
        Repo.insert_all(Line, cur)
      end)
      inserts[Word]
      |> Enum.chunk_every(16000)
      |> Enum.each(fn (cur) ->
        Repo.insert_all(Word, cur)
      end)
    end, timeout: :infinity)
  end

  def get_read(user_id, read_id) do
    # TODO add auth
    read = Read
           |> Repo.get!(read_id)

    proc = %{
      name: read.name,
    }

    {:ok, proc}
  end

  def list_reads(user_id) do
    reads_query = from r in Read,
                    select: r,
                    where: r.user_id == ^user_id,
                    order_by: r.updated_at # will be reversed anyway
    reads = reads_query
            |> Repo.all()

    proc = Enum.reduce(reads, [], fn (cur, acc) ->
      next = %{
        id: cur.id,
        name: cur.name,
      }
      [next | acc]
    end)

    {:ok, proc}
  end

  def create_read(user_id, read_attrs \\ %{}, source_url, configs_attrs) do
    Repo.transaction(fn ->
      # always a new read, only need read committed

      case read_attrs["type"] do
        "play" -> "play"
        _ -> raise "invalid read type"
      end

      read = %Read {
        user_id: user_id,
      }
      |> Read.changeset(read_attrs)
      |> Repo.insert!

      # grab source_attrs with HTTPoison
      result = HTTPoison.get!(source_url)
      # IO.inspect(result)

      if String.at(Integer.to_string(result.status_code), 0) != "2" do
        raise "fetching url failed"
      end

      source_attrs = %{
        value: result.body,
      }

      %Source {
        read_id: read.id,
      }
      |> Source.changeset(source_attrs)
      |> Repo.insert!

      Config
      |> Repo.insert_all(
        configs_attrs
        |> extract_configs_vanilla(read.id)
      )

      # actually need this to prevent bad concurrency artifacts
      %Character {
        name: "_none",
        read_id: read.id,
      }
      |> Repo.insert!

      # TODO: insert all at once
      # because its a new read and default widgets are only given once, we can add those in here
      # order of widgets are reversed bc of sort order
      # plot over interaction
      Widgets.create_widget(user_id, %{name: "All characters' participation heatmap", action: "plot over", item: "character", granularity: "interaction", from_all: true, read_id: read.id})
      Widgets.create_widget(user_id, %{name: "Top 2 characters' participation heatmap", action: "plot over", item: "character", granularity: "interaction", sort: "desc", take: 2, from_all: true, read_id: read.id})
      # plot over
      Widgets.create_widget(user_id, %{name: "All character participation over time", action: "plot over", item: "character", granularity: "scene", from_all: true, read_id: read.id})
      Widgets.create_widget(user_id, %{name: "Top 5 character participation over time", action: "plot over", item: "character", granularity: "scene", sort: "desc", take: 5, from_all: true, read_id: read.id})
      Widgets.create_widget(user_id, %{name: "Top 10 word usage over time", action: "plot over", item: "word", granularity: "scene", sort: "desc", take: 10, from_all: true, read_id: read.id})
      Widgets.create_widget(user_id, %{name: "Top 3 word usage over time (low granularity)", action: "plot over", item: "word", granularity: "interaction", sort: "desc", take: 3, from_all: true, read_id: read.id})
      # list + plot
      Widgets.create_widget(user_id, %{name: "All characters with their participation count", action: "list", item: "character", sort: "asc", from_all: true, read_id: read.id})
      Widgets.create_widget(user_id, %{name: "Characters that only talked once", action: "list", item: "character", sort: "asc", match_i: 1, from_all: true, read_id: read.id})
      Widgets.create_widget(user_id, %{name: "Characters that talked the most", action: "plot", item: "character", sort: "desc", take: 50, from_all: true, read_id: read.id})
      Widgets.create_widget(user_id, %{name: "All words with their use count", action: "list", item: "word", sort: "asc", from_all: true, read_id: read.id})
      Widgets.create_widget(user_id, %{name: "Words that were only used once", action: "list", item: "word", sort: "asc", match_i: 1, from_all: true, read_id: read.id})
      Widgets.create_widget(user_id, %{name: "Most frequently used words", action: "plot", item: "word", sort: "desc", take: 100, from_all: true, read_id: read.id})

      {:ok, read.id}
    end)
  end

  def delete_read(user_id, read_id) do
    # TODO really gotta check if user owns read

    Read
    |> Repo.get!(read_id)
    |> Repo.delete!

    {:ok}
  end

  defp extract_configs_vanilla(configs_attrs, read_id) do
    # configs is an array
    # for each array object
    configs_attrs
    |> Enum.reduce([], fn (config_attrs, final_acc) ->
      type = config_attrs["type"]
      # for each match index
      final = Enum.reduce(config_attrs["match"], {0, []}, fn (matches, matches_acc) ->
        configs = Enum.reduce(matches, [], fn (obj, acc) ->
          config = %{
            type: type,
            idx: elem(matches_acc, 0),
            match_type: obj["type"],
            match_value: obj["value"],
            read_id: read_id,
          }
          [config | acc]
        end)
        # increment idx, fast add to list
        {elem(matches_acc, 0) + 1, configs ++ elem(matches_acc, 1)}
      end)
      elem(final, 1) ++ final_acc
    end)
  end

  defp represent_configs(configs) do
    # TODO make configs more configurable
    # configs layout: %{%{"html" => %{"a" => "act", ..}, "text" => %{..}}, %{..}, ..} (layer, match type, ..
    # convert configs to matches (internal)
    Enum.reduce(configs, %{}, fn (cur, acc) ->
      acc = if acc[cur.idx] === nil do
        acc
        |> Map.put(cur.idx, %{})
      else
        acc
      end

      sub = if acc[cur.idx][cur.match_type] === nil do
        acc[cur.idx]
        |> Map.put(cur.match_type, %{})
      else
        acc[cur.idx]
      end

      sub_sub = if sub[cur.match_type][cur.match_value] === nil do
        sub[cur.match_type]
        |> Map.put(cur.match_value, MapSet.new())
      else
        sub[cur.match_type]
      end

      sub_sub_sub = sub_sub[cur.match_value]
                    |> MapSet.put(cur.type)

      sub_sub = sub_sub
                |> Map.put(cur.match_value, sub_sub_sub)
      sub = sub
            |> Map.put(cur.match_type, sub_sub)
      acc = acc
            |> Map.put(cur.idx, sub)
      acc
    end)
  end

  defp represent_stops(configs) do
    Enum.reduce(configs, %{}, fn (cur, acc) ->
      if acc[cur.type] === nil do
        acc
        |> Map.put(cur.type, cur.idx)
      else
        acc
        |> Map.put(cur.type, max(acc[cur.type], cur.idx))
      end
    end)
  end

  defp parse_play_imp(document, matches, stops, match, chars, active, inserts, depth) do
    # IO.puts("--- DEPTH #{depth} ---")
    Enum.reduce(document, %{chars: chars, active: active, inserts: inserts}, fn (cur, acc) ->
      with {tag, _props, content} <- cur do
        # is html
        #  step-able,                          matching anything,   or matched
        if matches[depth]["html"][tag] !== nil && (match === nil || !MapSet.disjoint?(matches[depth]["html"][tag], match)) do
          # step into sub-document
          if match === nil do
            parse_play_imp(content, matches, stops, matches[depth]["html"][tag], acc.chars, acc.active, acc.inserts, depth + 1)
          else
            # make sure to keep the root match
            parse_play_imp(content, matches, stops, MapSet.intersection(matches[depth]["html"][tag], match), acc.chars, acc.active, acc.inserts, depth + 1)
          end
        else
          acc
        end
      else text ->
        # is text
        # always will be last layer, once you see one text ur done
        if match !== nil && (matches[depth]["text"][Enum.at(String.split(text), 0)] === nil || !MapSet.disjoint?(matches[depth]["text"][Enum.at(String.split(text), 0)], match)) do
          # check if should add
          {text, type} = if matches[depth]["text"][Enum.at(String.split(text), 0)] === nil && matches[depth]["text"][nil] === nil do
            # if text no match, go by stop value
            {text, type} = if MapSet.size(match) == 1 && stops[Enum.at(MapSet.to_list(match), 0)] == depth - 1 do
              {text, Enum.at(MapSet.to_list(match), 0)}
            else
              {nil, nil}
            end
          else
            # if text matched, put it all the time
            this_match = if matches[depth]["text"][Enum.at(String.split(text), 0)] !== nil do
              MapSet.intersection(matches[depth]["text"][Enum.at(String.split(text), 0)], match)
            else
              match
            end
            {text, type} = if MapSet.size(this_match) == 1 do # && stops[Enum.at(MapSet.to_list(this_match), 0)] >= depth do
              {text, Enum.at(MapSet.to_list(this_match), 0)}
            else
              {nil, nil}
            end
          end

          # now everything starts here
          if text !== nil && type !== nil do
            # IO.inspect(acc)
            # IO.puts("'#{text}' #{type}\n")
            # TODO make it work with more binds
            # Binders: ★: spawn =>: strong, -> weak
            # Binds: ★ read => act => scene -> interaction => (controls | paragraphs => lines => words)
            case type do
              "act" ->
                act = %{
                  id: UUID.uuid4(),
                  idx: (if acc.active.act.idx === nil, do: 1, else: acc.active.act.idx + 1),
                  name: text,
                  read_id: acc.active.read_id,
                }
                acc_active = acc.active
                             |> Map.put(:act, %{id: act.id, idx: act.idx})
                             |> Map.put(:scene, %{id: nil, idx: nil})
                             |> Map.put(:interaction, %{id: nil, idx: nil})
                             |> Map.put(:paragraph, %{id: nil, idx: nil})
                             |> Map.put(:line_idx, nil)
                acc_inserts = Map.put(acc.inserts, Act, [act | acc.inserts[Act]])
                acc
                |> Map.put(:active, acc_active)
                |> Map.put(:inserts, acc_inserts)
              "scene" ->
                # TODO dirty hack for now but just set "PROLOGUE" to idx 0
                scene = %{
                  id: UUID.uuid4(),
                  idx: (if String.downcase(text) == "prologue", do: 0, else: (if acc.active.scene.idx === nil, do: 1, else: acc.active.scene.idx + 1)),
                  name: text,
                  act_id: acc.active.act.id,
                }
                acc_active = acc.active
                             |> Map.put(:scene, %{id: scene.id, idx: scene.idx})
                             |> Map.put(:interaction, %{id: nil, idx: nil})
                             |> Map.put(:paragraph, %{id: nil, idx: nil})
                             |> Map.put(:line_idx, nil)
                acc_inserts = Map.put(acc.inserts, Scene, [scene | acc.inserts[Scene]])
                acc
                |> Map.put(:active, acc_active)
                |> Map.put(:inserts, acc_inserts)
              "character" ->
                # create character if necessary
                # remove typos
                text = text
                       |> String.split()
                       |> Enum.join(" ")
                # remove colons for now
                text = text
                       |> String.replace(":", "")
                {acc_chars, acc_inserts} = if acc.chars[text] === nil do
                  character = %{
                    id: UUID.uuid4(),
                    name: text,
                    read_id: acc.active.read_id,
                  }
                  {Map.put(acc.chars, character.name, character.id), Map.put(acc.inserts, Character, [character | acc.inserts[Character]])}
                else
                  {acc.chars, acc.inserts}
                end
                # create interaction
                interaction = %{
                  id: UUID.uuid4(),
                  idx: (if acc.active.interaction.idx === nil, do: 1, else: acc.active.interaction.idx + 1),
                  character_id: acc_chars[text],
                  scene_id: acc.active.scene.id,
                }
                acc_active = acc.active
                             |> Map.put(:interaction, %{id: interaction.id, idx: interaction.idx})
                             |> Map.put(:paragraph, %{id: nil, idx: nil})
                             |> Map.put(:line_idx, nil)
                acc_inserts = Map.put(acc_inserts, Interaction, [interaction | acc_inserts[Interaction]])
                acc
                |> Map.put(:chars, acc_chars)
                |> Map.put(:active, acc_active)
                |> Map.put(:inserts, acc_inserts)
              "interaction" ->
                # the lowest denomination, will further split from this
                # create dummy interaction if it doesn't exist
                {acc_active, acc_inserts} = if acc.active.interaction.id === nil do
                  interaction = %{
                    id: UUID.uuid4(),
                    idx: 0, # TODO make this more flexible (prolly not even doable)
                    character_id: acc.chars.none,
                    scene_id: acc.active.scene.id,
                  }
                  {Map.put(acc.active, :interaction, %{id: interaction.id, idx: interaction.idx}), Map.put(acc.inserts, Interaction, [interaction | acc.inserts[Interaction]])}
                else
                  {acc.active, acc.inserts}
                end
                # check if need to make paragraph
                {acc_active, acc_inserts} = if acc_active.paragraph.id === nil do
                  paragraph = %{
                    id: UUID.uuid4(),
                    idx: (if acc_active.paragraph.idx === nil, do: 1, else: acc_active.paragraph.idx + 1),
                    interaction_id: acc_active.interaction.id,
                  }
                  {Map.put(acc_active, :paragraph, %{id: paragraph.id, idx: paragraph.idx}), Map.put(acc_inserts, Paragraph, [paragraph | acc_inserts[Paragraph]])}
                else
                  {acc_active, acc_inserts}
                end
                # create line
                line = %{
                  id: UUID.uuid4(),
                  idx: (if acc.active.line_idx === nil, do: 1, else: acc.active.line_idx + 1),
                  value: text,
                  paragraph_id: acc_active.paragraph.id,
                }
                acc_active = Map.put(acc_active, :line_idx, line.idx)
                acc_inserts = Map.put(acc_inserts, Line, [line | acc_inserts[Line]])
                # create words
                words = text
                |> String.replace(~r/(\.)|(\?)|(\!)|(\:)|(\;)|(\,)|(--)/, " ")
                |> String.replace(~r/\[[\s\S]*?\]/, "")
                |> String.downcase()
                |> String.split(" ", trim: true)
                |> Enum.reduce(%{}, fn (cur, acc) ->
                  if cur == "'" || cur == "&" || cur == "-" do
                    acc
                  else
                    acc
                    |> Map.put(cur, (if acc[cur] === nil, do: 1, else: acc[cur] + 1))
                  end
                end)
                word_inserts = Enum.reduce(words, [], fn ({key, val}, acc) ->
                  word = %{
                    id: UUID.uuid4(),
                    value: key,
                    cnt: val,
                    line_id: line.id,
                  }
                  [word | acc]
                end)
                acc_inserts = Map.put(acc_inserts, Word, word_inserts ++ acc_inserts[Word]);
                acc
                |> Map.put(:active, acc_active)
                |> Map.put(:inserts, acc_inserts)
              "control" ->
                # create dummy interaction if it doesn't exist
                {acc_active, acc_inserts} = if acc.active.interaction.id === nil do
                  interaction = %{
                    id: UUID.uuid4(),
                    idx: 0, # TODO make this more flexible (prolly not even doable)
                    character_id: acc.chars.none,
                    scene_id: acc.active.scene.id,
                  }
                  {Map.put(acc.active, :interaction, %{id: interaction.id, idx: interaction.idx}), Map.put(acc.inserts, Interaction, [interaction | acc.inserts[Interaction]])}
                else
                  {acc.active, acc.inserts}
                end
                # create control
                control = %{
                  id: UUID.uuid4(),
                  idx: (if acc_active.paragraph.idx === nil, do: 1, else: acc_active.paragraph.idx + 1),
                  value: text,
                  interaction_id: acc_active.interaction.id,
                }
                acc_active = Map.put(acc_active, :paragraph, %{id: nil, idx: control.idx})
                acc_inserts = Map.put(acc_inserts, Control, [control | acc_inserts[Control]])
                acc
                |> Map.put(:active, acc_active)
                |> Map.put(:inserts, acc_inserts)
              _ ->
                acc
            end
          else
            acc
          end
        else
          acc
        end
      end
    end)
  end
end
