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
limit 8000;

select * from reads
