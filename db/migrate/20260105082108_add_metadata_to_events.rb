class AddMetadataToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :metadata, :json, default: {}
  end
end
