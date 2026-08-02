require "test_helper"

class RecordingTest < ActiveSupport::TestCase
  test "create_for creates recordable, recording and created event" do
    assert_difference [ "Document.count", "Recording.count", "Event.count" ], +1 do
      recording = Recording.create_for(Document.new(title: "v1", body: "body1"))

      assert_equal "v1", recording.recordable.title
      assert_equal "body1", recording.recordable.body

      event = recording.events.sole
      assert event.was_created?
      assert_equal recording.recordable, event.recordable
    end
  end

  test "create_for works for articles" do
    assert_difference [ "Article.count", "Recording.count", "Event.count" ], +1 do
      recording = Recording.create_for(Article.new(title: "a1", body: "b1", url: "https://example.com"))

      assert recording.article?
      assert recording.events.sole.was_created?
    end
  end

  test "create_for stores actor_name and metadata" do
    recording = Recording.create_for Article.new(title: "a1", body: "b", url: "https://example.com"),
      actor_name: "web", metadata: { source: "test", request_id: "req-123" }

    event = recording.events.sole
    assert_equal "web", event.actor_name
    assert_equal "test", event.source
    assert_equal "req-123", event.request_id
    assert_equal "test", event.metadata["source"]
  end

  test "update_document swaps the recordable and records the changed fields" do
    recording = Recording.create_for(Document.new(title: "v1", body: "body1"))
    previous = recording.recordable

    assert_difference [ "Document.count", "recording.events.count" ], +1 do
      recording.update_document Document.new(title: "v2", body: "body2")
    end

    recording.reload
    assert_not_equal previous, recording.recordable
    assert_equal "v2", recording.recordable.title

    event = recording.events.recent.first
    assert event.was_updated?
    assert_equal recording.recordable, event.recordable
    assert_equal %w[ title body ], event.changed_fields
  end

  test "update_document records only the fields that changed" do
    recording = Recording.create_for(Document.new(title: "v1", body: "body1"))
    recording.update_document Document.new(title: "v1", body: "body2")

    assert_equal [ "body" ], recording.events.recent.first.changed_fields
  end

  test "update_document is a no-op when nothing changed" do
    recording = Recording.create_for(Document.new(title: "v1", body: "body1"))

    assert_no_difference [ "Document.count", "recording.events.count" ] do
      recording.update_document Document.new(title: "v1", body: "body1")
    end
  end

  test "soft_delete moves the recording from active to deleted" do
    recording = Recording.create_for(Document.new(title: "v1", body: "body1"))

    assert_includes Recording.active, recording

    assert_difference "recording.events.count", +1 do
      recording.soft_delete
    end

    assert recording.deleted?
    assert_includes Recording.deleted, recording
    assert_not_includes Recording.active, recording
    assert recording.events.recent.first.was_destroyed?
  end

  test "restore clears deleted_at" do
    recording = Recording.create_for(Article.new(title: "a1", body: "b", url: "https://example.com"))
    recording.soft_delete

    assert_difference "recording.events.count", +1 do
      recording.restore
    end

    assert_not recording.deleted?
    assert_includes Recording.active, recording
    assert recording.events.recent.first.was_restored?
  end

  test "delegated type scopes" do
    document = Recording.create_for(Document.new(title: "d1", body: "b"))
    article  = Recording.create_for(Article.new(title: "a1", body: "b", url: "https://example.com"))

    assert_includes Recording.documents, document
    assert_not_includes Recording.documents, article

    assert_includes Recording.articles, article
    assert_not_includes Recording.articles, document
  end
end
