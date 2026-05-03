class Recording < ApplicationRecord
  include RecordsEvents
  include Recording::RecordableCreation
  include Recording::DocumentUpdating

  class DeletedRecordingError < StandardError; end
  class NotDeletedRecordingError < StandardError; end
  class UnsupportedRecordableError < StandardError; end

  delegated_type :recordable, types: %w[Document Article], inverse_of: :recording

  scope :active,  -> { where(deleted_at: nil) }
  scope :deleted, -> { where.not(deleted_at: nil) }

  def deleted?
    deleted_at.present?
  end

  def article?
    recordable_type == "Article"
  end

  # --- Public API (use cases) ---

  def self.create_with_document!(document_params, actor_name: nil, metadata: nil)
    document = Document.create!(document_params)
    create_with_recordable!(document, actor_name: actor_name, metadata: metadata)
  end

  def self.create_with_article!(article_params, actor_name: nil, metadata: nil)
    article = Article.create!(article_params)
    create_with_recordable!(article, actor_name: actor_name, metadata: metadata)
  end

  def update_with_new_document!(document_params, actor_name: nil, metadata: nil)
    transaction do
      ensure_not_deleted!
      ensure_document_recording!
      swap_and_record_update!(document_params, actor_name: actor_name, metadata: metadata)
    end
    self
  end

  def soft_delete_with_event!(actor_name: nil, metadata: nil)
    transaction do
      ensure_not_deleted!
      update!(deleted_at: Time.current)
      add_event!("destroyed", recordable, actor_name: actor_name, metadata: metadata)
    end
    self
  end

  def restore_with_event!(actor_name: nil, metadata: nil)
    transaction do
      raise NotDeletedRecordingError, "not deleted" unless deleted?

      update!(deleted_at: nil)
      add_event!("restored", recordable, actor_name: actor_name, metadata: metadata)
    end
    self
  end

  private

    def ensure_not_deleted!
      raise DeletedRecordingError, "deleted recording" if deleted?
    end
end
