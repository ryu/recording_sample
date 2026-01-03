class Event < ApplicationRecord
  belongs_to :recording
  belongs_to :recordable, polymorphic: true

  enum :action_type, {
    created: "created",
    updated: "updated",
    destroyed: "destroyed"
  }, prefix: true

  validates :action_type, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
