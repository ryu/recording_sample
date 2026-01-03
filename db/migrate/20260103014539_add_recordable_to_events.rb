class AddRecordableToEvents < ActiveRecord::Migration[8.1]
  def change
    add_reference :events, :recordable, polymorphic: true
  end
end
