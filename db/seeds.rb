5.times do
  article = Article.create!(
    title: Faker::Company.catch_phrase,
    body: Faker::Lorem.paragraph(sentence_count: 2)
  )

  3.times do
    article.comments.create!(body: Faker::Books::Dune.quote,
                             commenter: Faker::Books::Dune.character)
  end
end
