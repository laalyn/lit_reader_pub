select words.value, sum(words.cnt) from reads
join acts on reads.id = acts.read_id
join scenes on acts.id = scenes.act_id
join interactions on scenes.id = interactions.scene_id
join paragraphs on interactions.id = paragraphs.interaction_id
join lines on paragraphs.id = lines.paragraph_id
join words on lines.id = words.line_id
where reads.id = '51f8e4f3-210e-4702-a344-76fdcdc111fd'
group by words.value
having sum(words.cnt) = 1
order by sum desc, words.value;
