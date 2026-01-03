class AddRecordableToRecordings < ActiveRecord::Migration[8.1]
  def change
    add_column :recordings, :recordable_id, :integer
    add_column :recordings, :recordable_type, :string
  end
end
