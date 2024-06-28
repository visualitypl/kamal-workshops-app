class DeleteBaronsCommentsJob < ApplicationJob
  queue_as :default

  def perform(article)
    article.comments.where("commenter LIKE '%Baron%'").destroy_all
  end
end
