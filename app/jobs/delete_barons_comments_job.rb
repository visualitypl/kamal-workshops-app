class DeleteBaronsCommentsJob < ApplicationJob
  queue_as :default

  def perform(article)
    article.comments.where("commenter LIKE '%Baron%'").or(article.comments.where("commenter LIKE '%Harkonnen%'")).destroy_all
  end
end
