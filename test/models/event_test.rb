require "test_helper"

class EventTest < ActiveSupport::TestCase
  test "action_type must be in ACTIONS" do
    recording = Recording.create!(recordable: Document.create!(title: "title", body: "body"))

    event = recording.events.build(recordable: recording.recordable, action_type: "typo")
    assert_not event.valid?
    assert_includes event.errors[:action_type], "is not included in the list"
  end
end
