class ArticlesController < ApplicationController
  def index
    # area filter
  end

  def show
    add_breadcrumb t('article')
    @article = Article.find(params[:id])
    @articles = Article.where(article_type_id: @article.article_type_id).order(updated_at: :desc).page(params[:page]).per(24)
    add_breadcrumb @article.article_type.name
    add_breadcrumb @article.title
  end
end