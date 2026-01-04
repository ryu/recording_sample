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
      recording = create!(recordable: document)

      recording.add_event!("created", document)

      recording
    end
  end

  def update_with_new_document!(document_params)
    self.class.transaction do
      raise "deleted recording" if deleted?

      document = Document.create!(document_params)
      update!(recordable: document)
      add_event!("updated", document)

      self
    end
  end

  def soft_delete_with_event!
    self.class.transaction do
      add_event!("destroyed", recordable)
      update!(deleted_at: Time.current)
    end
  end

  def restore_with_event!
    raise "not deleted" unless deleted?
    update!(deleted_at: nil)
    add_event!("restored", recordable)
  end

  def add_event!(action, snapshot)
    events.create!(action_type: action, recordable: snapshot)
  end
end
