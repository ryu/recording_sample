class TightenRecordingSchema < ActiveRecord::Migration[8.1]
  def up
    add_index :recordings, [ :recordable_type, :recordable_id ], name: "index_recordings_on_recordable"

    execute "DELETE FROM events WHERE action_type IS NULL"
    execute "UPDATE events SET metadata = '{}' WHERE metadata IS NULL"

    change_column_null :events, :action_type, false
    change_column_null :events, :metadata, false

    remove_index :events, :actor_name
    remove_column :events, :actor_id
  end

  def down
    add_column :events, :actor_id, :integer
    add_index :events, :actor_id
    add_index :events, :actor_name

    change_column_null :events, :metadata, true
    change_column_null :events, :action_type, true

    remove_index :recordings, name: "index_recordings_on_recordable"
  end
end
