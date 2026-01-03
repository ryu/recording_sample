class CreateRecordings < ActiveRecord::Migration[8.1]
  def change
    create_table :recordings do |t|
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
