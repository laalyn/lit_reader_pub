select acts.idx, acts.name, scenes.idx, scenes.name, interactions.idx, characters.name, paragraphs.idx, lines.idx, lines.value from reads
join characters on reads.id = characters.read_id
join acts on reads.id = acts.read_id
join scenes on acts.id = scenes.act_id
join interactions on scenes.id = interactions.scene_id and characters.id = interactions.character_id
join paragraphs on interactions.id = paragraphs.interaction_id
join lines on paragraphs.id = lines.paragraph_id
where reads.id = '8363f5f8-afb8-4651-bc19-bb29e18900f3'
  and character_id = '12f2d03a-fc49-4ca5-85f1-b7d92a84b9d6'
order by acts.idx, scenes.idx, interactions.idx, paragraphs.idx, lines.idx
limit 8000;


select *
from reads;
