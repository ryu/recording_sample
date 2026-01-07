class AddActorNameToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :actor_name, :string
    add_index :events, :actor_name
  end
end
