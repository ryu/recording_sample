class AddRequestIdAndSourceToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :request_id, :string
    add_column :events, :source, :string
  end
end
