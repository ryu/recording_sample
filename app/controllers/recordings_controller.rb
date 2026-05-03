class RecordingsController < ApplicationController
  rescue_from Recording::DeletedRecordingError do
    redirect_to recordings_path, status: :see_other, alert: "削除済みのため更新できません。"
  end

  rescue_from Recording::NotDeletedRecordingError do
    redirect_to recordings_path, status: :see_other, alert: "削除されていないため復元できません。"
  end

  rescue_from Recording::UnsupportedRecordableError do
    redirect_to recordings_path, status: :see_other, alert: "この種類は更新できません。"
  end
  def index
    @recordings = Recording.active
                           .includes(:recordable)
                           .order(created_at: :desc)
  end

  def new
    @recording = Recording.new
    @document = Document.new
    @article = Article.new
  end

  def create
    @recording =
      if params[:document]
        Recording.create_with_document!(document_params, actor_name: "web", metadata: audit_context)
      elsif params[:article]
        Recording.create_with_article!(article_params, actor_name: "web", metadata: audit_context)
      else
        raise ActionController::BadRequest, "missing document/article params"
      end

    redirect_to @recording
  rescue ActiveRecord::RecordInvalid
    @recording ||= Recording.new
    @document ||= Document.new(document_params) if params[:document]
    @article ||= Article.new(article_params) if params[:article]
    render :new, status: :unprocessable_entity
  end

  def show
    @recording = Recording.find(params[:id])
    @events = @recording.events.recent.includes(:recordable)
  end

  def edit
    @recording = Recording.find(params[:id])
    @document = @recording.recordable
  end

  def update
    @recording = Recording.find(params[:id])
    @recording.update_with_new_document!(document_params, actor_name: "web", metadata: audit_context)

    redirect_to recording_path(@recording), status: :see_other, notice: "更新しました。"
  rescue ActiveRecord::RecordInvalid
    @document = @recording.recordable
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @recording = Recording.find(params[:id])
    @recording.soft_delete_with_event!(actor_name: "web", metadata: audit_context)

    redirect_to recordings_path, notice: "削除しました。"
  end

  def restore
    recording = Recording.find(params[:id])
    recording.restore_with_event!(actor_name: "web", metadata: audit_context)
    redirect_to recordings_path, status: :see_other, notice: "復元しました。"
  end

  private

    def audit_context
      { source: "web", request_id: request.request_id }
    end

    def document_params
      params.expect(document: [ :title, :body ])
    end

    def article_params
      params.expect(article: [ :title, :body, :url ])
    end
end
