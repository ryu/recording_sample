class AddIndexToEventsRequestId < ActiveRecord::Migration[8.1]
  def change
    add_index :events, :request_id
  end
end
