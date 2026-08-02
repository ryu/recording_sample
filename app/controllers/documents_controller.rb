class DocumentsController < ApplicationController
  def new
    @document = Document.new
  end

  def create
    @document = Document.new(document_params)

    if @document.valid?
      redirect_to Recording.create_for(@document, **audit_context)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def document_params
      params.expect(document: [ :title, :body ])
    end
end
