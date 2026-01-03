class Recording < ApplicationRecord
  delegated_type :recordable, types: %w[Document], inverse_of: :recording
  has_many :events, dependent: :destroy

  scope :active, -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  def deleted?
    deleted_at.present?
  end

  def self.create_with_document!(document_params)
    transaction do
      document = Document.create!(document_params)
      recording = Recording.create!(recordable: document)

      recording.events.create!(
        recordable: document,
        action_type: "created",
      )

      recording
    end
  end

  def update_with_document!(document_params)
    self.class.transaction do
      document = Document.create!(document_params)

      update!(recordable: document)

      events.create!(
        recordable: document,
        action_type: "updated"
      )
    end
  end

  def soft_delete_with_event!
    self.class.transaction do
      current_document = recordable

      events.create!(
        recordable: current_document,
        action_type: "destroyed"
      )

      update!(deleted_at: Time.current)
    end
  end
end
