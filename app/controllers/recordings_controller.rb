class RecordingsController < ApplicationController
  def index
    @recordings = Recording.active
                           .documents
                           .includes(:recordable)
                           .order(created_at: :desc)
  end

  def new
    @recording = Recording.new
    @document = Document.new
  end

  def create
    @recording = Recording.create_with_document!(document_params)
    redirect_to @recording
  rescue ActiveRecord::RecordInvalid
    @recording ||= Recording.new
    @document ||= Document.new(document_params)
    render :new, status: :unprocessable_entity
  end

  def show
    @recording = Recording.find(params[:id])
  end

  def edit
    @recording = Recording.find(params[:id])
    @document = @recording.recordable
  end

  def update
    @recording = Recording.find(params[:id])
    @recording.update_with_new_document!(document_params)

    redirect_to @recording
  rescue ActiveRecord::RecordInvalid
    @document = @recording.recordable
    render :edit, status: :unprocessable_entity
  end

  def destroy
    @recording = Recording.find(params[:id])
    @recording.soft_delete_with_event!

    redirect_to recordings_path, notice: "Recording was deleted."
  rescue ActiveRecord::RecordInvalid
    redirect_to @recording, alert: "Failed to delete recording."
  end

  private

    def document_params
      params.expect(document: [:title, :body])
    end
end
