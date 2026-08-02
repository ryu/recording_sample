class ArticlesController < ApplicationController
  def new
    @article = Article.new
  end

  def create
    @article = Article.new(article_params)

    if @article.valid?
      redirect_to Recording.create_for(@article, **audit_context)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def article_params
      params.expect(article: [ :title, :body, :url ])
    end
end
