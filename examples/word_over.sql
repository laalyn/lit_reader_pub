select acts.idx, acts.name, scenes.idx, scenes.name, interactions.idx, characters.name, words.value, sum(words.cnt) from reads
join characters on reads.id = characters.read_id
join acts on reads.id = acts.read_id
join scenes on acts.id = scenes.act_id
join interactions on scenes.id = interactions.scene_id and characters.id = interactions.character_id
join paragraphs on interactions.id = paragraphs.interaction_id
join lines on paragraphs.id = lines.paragraph_id
join words on lines.id = words.line_id
where reads.id = '795da1e0-3e0c-4e05-aa9b-ba2e7ba9c863'
  and words.value in (
    select value from ( -- cannot be words.value !! only value !
      select words.value, sum(words.cnt) from reads
      join acts on reads.id = acts.read_id
      join scenes on acts.id = scenes.act_id
      join interactions on scenes.id = interactions.scene_id
      join paragraphs on interactions.id = paragraphs.interaction_id
      join lines on paragraphs.id = lines.paragraph_id
      join words on lines.id = words.line_id
      where reads.id = '795da1e0-3e0c-4e05-aa9b-ba2e7ba9c863'
      group by words.value
      order by sum desc, words.value
      limit 3
    ) as sub
  )
group by acts.idx, acts.name, scenes.idx, scenes.name, interactions.idx, characters.name, words.value
order by acts.idx, scenes.idx, interactions.idx, characters.name, words.value
limit 8000;
