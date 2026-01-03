class AddDocumentToRecordings < ActiveRecord::Migration[8.1]
  def change
    add_reference :recordings, :document, foreign_key: true
  end
end
