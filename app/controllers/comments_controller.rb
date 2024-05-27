class CommentsController < ApplicationController
  # POST /comments
  def create
    @article = Article.find(params[:article_id])
    @comment = @article.comments.create(comment_params)
    redirect_to article_path(@article)
  end

  def destroy
    @article = Article.find(params[:article_id])
    @comment = @article.comments.find(params[:id])
    @comment.destroy!
    redirect_to article_path(@article), notice: "Comment was successfully destroyed.", status: :see_other
  end

  private
    # Only allow a list of trusted parameters through.
    def comment_params
      params.require(:comment).permit(:commenter, :body)
    end
end
