class Event < ApplicationRecord
  ACTIONS = %w[created updated destroyed restored].freeze

  ACTION_LABELS = {
    "created"   => "作成",
    "updated"   => "更新",
    "destroyed" => "削除",
    "restored"  => "復元"
  }.freeze

  belongs_to :recording
  belongs_to :recordable, polymorphic: true

  validates :action_type, presence: true, inclusion: { in: ACTIONS }
  validates :actor_name, length: { maximum: 100 }, allow_nil: true

  scope :recent, -> { order(created_at: :desc) }

  # --- Display helpers ---

  def action_label
    ACTION_LABELS.fetch(action_type, action_type)
  end

  def recordable_title
    recordable&.title || "##{recordable_id}"
  end

  def actor_label
    actor_name.presence
  end

  # --- Metadata helpers ---

  def metadata_hash
    metadata.is_a?(Hash) ? metadata : {}
  end

  def changed_fields
    Array(metadata_hash["changed_fields"])
  end

  # --- Predicates ---

  def updated?
    action_type == "updated"
  end

  def title_changed?
    updated? && changed_fields.include?("title")
  end
end
