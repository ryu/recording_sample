class Recording < ApplicationRecord
  include RecordsEvents
  class DeletedRecordingError < StandardError; end
  class NotDeletedRecordingError < StandardError; end

  delegated_type :recordable, types: %w[Document], inverse_of: :recording

  scope :active,  -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  def deleted?
    deleted_at.present?
  end

  # --- Public API (use cases) ---

  def self.create_with_document!(document_params, actor_name: nil, metadata: nil)
    transaction do
      document  = Document.create!(document_params)
      recording = create!(recordable: document)

      recording.add_event!("created", document, actor_name: actor_name, metadata: metadata)

      recording
    end
  end

  def update_with_new_document!(document_params, actor_name: nil, metadata: nil)
    transaction do
      ensure_not_deleted!

      previous, document = build_new_document_and_swap!(document_params)

      add_updated_event!(previous, document, actor_name: actor_name, metadata: metadata)

      self
    end
  end

  def soft_delete_with_event!(actor_name: nil, metadata: nil)
    transaction do
      add_event!("destroyed", recordable, actor_name: actor_name, metadata: metadata)
      update!(deleted_at: Time.current)
      self
    end
  end

  def restore_with_event!(actor_name: nil, metadata: nil)
    transaction do
      raise NotDeletedRecordingError, "not deleted" unless deleted?

      update!(deleted_at: nil)
      add_event!("restored", recordable, actor_name: actor_name, metadata: metadata)

      self
    end
  end

  # --- Internal helpers ---

  private

    def changed_fields_for(previous, current)
      changed = []
      changed << "title" if previous.title != current.title
      changed
    end

    def ensure_not_deleted!
      raise DeletedRecordingError, "deleted recording" if deleted?
    end

    def build_new_document_and_swap!(document_params)
      previous = recordable
      document = Document.create!(document_params)
      update!(recordable: document)
      [previous, document]
    end

    def add_updated_event!(previous, document, actor_name:, metadata:)
      event_metadata =
        merge_metadata(
          metadata,
          "changed_fields" => changed_fields_for(previous, document)
        )

      add_event!("updated", document, actor_name: actor_name, metadata: event_metadata)
    end
end
