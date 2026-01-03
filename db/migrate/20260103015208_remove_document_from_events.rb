class RemoveDocumentFromEvents < ActiveRecord::Migration[8.1]
  def change
    remove_reference :events, :document, null: false, foreign_key: true
  end
end
