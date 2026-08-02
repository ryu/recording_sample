class RestorationsController < ApplicationController
  def create
    recording = Recording.deleted.find(params[:recording_id])
    recording.restore(**audit_context)

    redirect_to recording, status: :see_other, notice: "復元しました。"
  end
end
