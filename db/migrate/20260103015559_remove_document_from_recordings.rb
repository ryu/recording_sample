class RemoveDocumentFromRecordings < ActiveRecord::Migration[8.1]
  def change
    remove_reference :recordings, :document, null: false, foreign_key: true
  end
end
