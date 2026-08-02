class Recording < ApplicationRecord
  has_many :events, dependent: :destroy

  delegated_type :recordable, types: %w[ Document Article ], inverse_of: :recording

  scope :active,  -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  def self.create_for(recordable, actor_name: nil, metadata: nil)
    transaction do
      create!(recordable: recordable).tap do |recording|
        recording.record_event "created", recordable, actor_name: actor_name, metadata: metadata
      end
    end
  end

  def deleted?
    deleted_at.present?
  end

  def update_document(document, actor_name: nil, metadata: nil)
    changed_fields = document.changed_fields_from(recordable)
    return self if changed_fields.empty?

    transaction do
      update! recordable: document
      record_event "updated", document, actor_name: actor_name,
        metadata: metadata.to_h.merge("changed_fields" => changed_fields)
    end

    self
  end

  def soft_delete(actor_name: nil, metadata: nil)
    transaction do
      update! deleted_at: Time.current
      record_event "destroyed", recordable, actor_name: actor_name, metadata: metadata
    end

    self
  end

  def restore(actor_name: nil, metadata: nil)
    transaction do
      update! deleted_at: nil
      record_event "restored", recordable, actor_name: actor_name, metadata: metadata
    end

    self
  end

  def record_event(action, recordable, actor_name: nil, metadata: nil)
    metadata = metadata.to_h.stringify_keys

    events.create! action_type: action, recordable: recordable, actor_name: actor_name,
      request_id: metadata["request_id"], source: metadata["source"], metadata: metadata
  end
end
