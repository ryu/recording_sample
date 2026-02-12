module RecordsEvents
  extend ActiveSupport::Concern

  included do
    has_many :events, dependent: :destroy
  end

  def add_event!(action, snapshot, actor_name: nil, metadata: nil)
    meta = normalize_metadata(metadata)

    events.create!(
      action_type: action,
      recordable: snapshot,
      actor_name: actor_name,
      request_id: meta[:request_id] || meta["request_id"],
      source: meta[:source] || meta["source"],
      metadata: meta
    )
  end
  private

    def normalize_metadata(metadata)
      metadata.present? ? metadata : {}
    end

    def merge_metadata(base, extra)
      normalize_metadata(base).merge(extra)
    end
end
