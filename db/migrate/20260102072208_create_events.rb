class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.string :action_type
      t.belongs_to :recording, null: false, foreign_key: true
      t.belongs_to :document, null: false, foreign_key: true

      t.timestamps
    end
  end
end
