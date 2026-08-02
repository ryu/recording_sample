class RecordingsController < ApplicationController
  def index
    @recordings = Recording.active.includes(:recordable).order(created_at: :desc)
  end

  def show
    @recording = Recording.find(params[:id])
    @events = @recording.events.recent.includes(:recordable)
  end

  def edit
    @recording = Recording.active.documents.find(params[:id])
    @document = @recording.recordable
  end

  def update
    @recording = Recording.active.documents.find(params[:id])
    @document = Document.new(document_params)

    if @document.valid?
      @recording.update_document(@document, **audit_context)
      redirect_to @recording, status: :see_other, notice: "更新しました。"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    Recording.active.find(params[:id]).soft_delete(**audit_context)

    redirect_to recordings_path, status: :see_other, notice: "削除しました。"
  end

  private
    def document_params
      params.expect(document: [ :title, :body ])
    end
end
