module Recording::RecordableCreation
  extend ActiveSupport::Concern

  class_methods do
    private

      def create_with_recordable!(recordable, actor_name:, metadata:)
        transaction do
          recording = create!(recordable: recordable)
          recording.add_event!("created", recordable, actor_name: actor_name, metadata: metadata)
          recording
        end
      end
  end
end
