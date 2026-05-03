module Recording::DocumentUpdating
  extend ActiveSupport::Concern

  private

    def ensure_document_recording!
      return if recordable_type == "Document"
      raise Recording::UnsupportedRecordableError, "cannot update as Document for #{recordable_type}"
    end

    def swap_and_record_update!(document_params, actor_name:, metadata:)
      return if changed_fields_for(recordable, Document.new(document_params)).empty?

      previous, document = build_new_document_and_swap!(document_params)
      add_updated_event!(previous, document, actor_name: actor_name, metadata: metadata)
    end

    def build_new_document_and_swap!(document_params)
      previous = recordable
      document = Document.create!(document_params)
      update!(recordable: document)
      [ previous, document ]
    end

    def changed_fields_for(previous, current)
      changed = []
      changed << "title" if previous.title != current.title
      changed << "body"  if previous.body  != current.body
      changed
    end

    def add_updated_event!(previous, document, actor_name:, metadata:)
      event_metadata =
        merge_metadata(
          metadata,
          "changed_fields" => changed_fields_for(previous, document),
          "before" => { "title" => previous.title, "body" => previous.body },
          "after" => { "title" => document.title, "body" => document.body }
        )

      add_event!("updated", document, actor_name: actor_name, metadata: event_metadata)
    end
end
