class Event < ApplicationRecord
  ACTIONS = %w[ created updated destroyed restored ].freeze

  belongs_to :recording
  belongs_to :recordable, polymorphic: true

  validates :action_type, presence: true, inclusion: { in: ACTIONS }

  scope :recent, -> { order(created_at: :desc) }
end
