class Event < ApplicationRecord
  belongs_to :recording
  belongs_to :recordable, polymorphic: true

  enum :action_type, { created: "created", updated: "updated", destroyed: "destroyed", restored: "restored" },
    prefix: :was, validate: true

  validates :actor_name, length: { maximum: 100 }, allow_nil: true

  scope :recent, -> { order(created_at: :desc) }

  def action_label
    I18n.t action_type, scope: "events.action_types"
  end

  def changed_fields
    Array(metadata["changed_fields"])
  end
end
