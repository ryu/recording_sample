module RecordsEvents
  extend ActiveSupport::Concern

  included do
    has_many :events, dependent: :destroy
  end

  def add_event!(action, snapshot, actor_name: nil, metadata: nil)
    events.create!(
      action_type: action,
      recordable: snapshot,
      actor_name: actor_name,
      metadata: normalize_metadata(metadata)
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
