select acts.idx, acts.name as act_name, scenes.idx, scenes.name, interactions.idx, characters.name, count(*) from reads
join characters on reads.id = characters.read_id
join acts on reads.id = acts.read_id
join scenes on acts.id = scenes.act_id
join interactions on scenes.id = interactions.scene_id and characters.id = interactions.character_id
where reads.id = '795da1e0-3e0c-4e05-aa9b-ba2e7ba9c863'
  and characters.name in (
    select name from (
      select characters.name, count(*) from reads
      join characters on reads.id = characters.read_id
      join acts on reads.id = acts.read_id
      join scenes on acts.id = scenes.act_id
      join interactions on scenes.id = interactions.scene_id and characters.id = interactions.character_id
      where reads.id = '795da1e0-3e0c-4e05-aa9b-ba2e7ba9c863'
      group by characters.name
      order by count desc, characters.name
      limit 3
    ) as sub
  )
group by acts.idx, acts.name, scenes.idx, scenes.name, interactions.idx, characters.name
order by acts.idx, scenes.idx, interactions.idx, characters.name, count
limit 8000;
