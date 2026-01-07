class AddActorIdToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :actor_id, :integer
    add_index :events, :actor_id
  end
end
