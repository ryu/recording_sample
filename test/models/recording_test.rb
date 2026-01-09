# test/models/recording_test.rb
require "test_helper"

class RecordingTest < ActiveSupport::TestCase
  test "create_with_document! creates document, recording and created event" do
    params = { title: "v1", body: "body1" }

    assert_difference [ "Document.count", "Recording.count", "Event.count" ], +1 do
      recording = Recording.create_with_document!(params)

      assert_instance_of Recording, recording
      assert_instance_of Document,  recording.recordable

      document = recording.recordable

      assert_equal "v1",   document.title
      assert_equal "body1", document.body

      event = recording.events.last
      assert_equal "created", event.action_type
      assert_equal recording, event.recording
      assert_equal document,  event.recordable
    end
  end

  test "update_with_new_document! creates new document, switches recordable and adds updated event" do
    # まず最初の v1 を作る
    initial_params = { title: "v1", body: "body1" }
    recording      = Recording.create_with_document!(initial_params)
    first_document = recording.recordable

    # v2 への更新
    update_params = { title: "v2", body: "body2" }

    assert_difference "Document.count", +1 do
      assert_difference "recording.events.count", +1 do
        recording.update_with_new_document!(update_params)
      end
    end

    recording.reload
    second_document = recording.recordable

    # 別レコードになっていること
    refute_equal first_document.id, second_document.id
    assert_equal "v2",   second_document.title
    assert_equal "body2", second_document.body

    # 最後のイベントが updated で v2 を指している
    last_event = recording.events.order(:created_at).last
    assert_equal "updated", last_event.action_type
    assert_equal recording, last_event.recording
    assert_equal second_document, last_event.recordable
  end

  test "soft_delete_with_event! sets deleted_at, adds destroyed event and moves from active to deleted" do
    params    = { title: "v1", body: "body1" }
    recording = Recording.create_with_document!(params)

    assert_nil recording.deleted_at
    assert_includes Recording.active, recording
    refute_includes Recording.deleted, recording

    assert_difference "recording.events.count", +1 do
      recording.soft_delete_with_event!
    end

    recording.reload

    assert recording.deleted?
    assert_not_nil recording.deleted_at

    refute_includes Recording.active, recording
    assert_includes Recording.deleted, recording

    last_event = recording.events.order(:created_at).last
    assert_equal "destroyed", last_event.action_type
    assert_equal recording,   last_event.recording
    assert_equal recording.recordable, last_event.recordable
  end

  test "update_with_new_document! raises when recording is deleted" do
    recording = Recording.create_with_document!({ title: "v1", body: "body1" })
    recording.soft_delete_with_event!
    recording.reload

    assert recording.deleted?

    assert_raises(Recording::DeletedRecordingError) do
      recording.update_with_new_document!({ title: "v2", body: "body2" })
    end
  end

  test "restore_with_event! clears deleted_at and adds restored event" do
    recording = Recording.create_with_document!({ title: "v1", body: "body1" }, actor_name: "web")
    recording.soft_delete_with_event!
    recording.reload

    assert recording.deleted?

    assert_difference "recording.events.count", +1 do
      recording.restore_with_event!
    end

    recording.reload
    assert_not recording.deleted?

    last_event = recording.events.order(:created_at).last
    assert_equal "restored", last_event.action_type
    assert_equal recording, last_event.recording
    assert_equal recording.recordable, last_event.recordable
  end

  test "events store actor_name when provided" do
    recording = Recording.create_with_document!({ title: "v1", body: "body1" }, actor_name: "web")

    event = recording.events.order(:created_at).last
    assert_equal "created", event.action_type
    assert_equal "web", event.actor_name
  end

  test "update_with_new_document! raises for article recording" do
    recording = Recording.create_with_article!(
      { title: "a1", body: "b", url: "https://example.com" }
    )

    assert_raises Recording::UnsupportedRecordableError do
      recording.update_with_new_document!({ title: "v2", body: "x" })
    end
  end

  test "create_with_article! creates article, recording and created event" do
    params = { title: "a1", body: "b1", url: "https://example.com" }

    assert_difference %w[Article.count Recording.count Event.count], +1 do
      recording = Recording.create_with_article!(params)

      assert_equal "Article", recording.recordable_type
      assert_instance_of Article, recording.recordable

      event = recording.events.order(:created_at).last
      assert_equal "created", event.action_type
      assert_equal recording, event.recording
      assert_equal recording.recordable, event.recordable
    end
  end

  test "soft_delete_with_event! works for article recording" do
    recording = Recording.create_with_article!({ title: "a1", body: "b", url: "https://example.com" })

    assert_difference "recording.events.count", +1 do
      recording.soft_delete_with_event!
    end

    recording.reload
    assert recording.deleted?

    event = recording.events.order(:created_at).last
    assert_equal "destroyed", event.action_type
  end

  test "restore_with_event! works for article recording" do
    recording = Recording.create_with_article!({ title: "a1", body: "b", url: "https://example.com" })
    recording.soft_delete_with_event!

    assert_difference "recording.events.count", +1 do
      recording.restore_with_event!
    end

    recording.reload
    refute recording.deleted?

    event = recording.events.order(:created_at).last
    assert_equal "restored", event.action_type
  end

  test "create_with_article! stores actor_name and metadata" do
    recording = Recording.create_with_article!(
      { title: "a1", body: "b", url: "https://example.com" },
      actor_name: "web",
      metadata: { "source" => "test" }
    )

    event = recording.events.order(:created_at).last
    assert_equal "web", event.actor_name
    assert_equal "test", event.metadata["source"]
  end

  test "type scopes work: Recording.documents and Recording.articles" do
    doc = Recording.create_with_document!({ title: "d1", body: "b" })
    art = Recording.create_with_article!({ title: "a1", body: "b", url: "https://example.com" })

    assert_includes Recording.documents, doc
    refute_includes Recording.documents, art

    assert_includes Recording.articles, art
    refute_includes Recording.articles, doc
  end

  test "updated event stores changed_fields for title" do
    recording = Recording.create_with_document!({ title: "v1", body: "body1" })

    recording.update_with_new_document!({ title: "v2", body: "body1" })

    event = recording.events.order(:created_at).last
    assert_equal "updated", event.action_type
    assert_equal [ "title" ], event.metadata["changed_fields"]
  end

  test "restore_with_event! raises when recording is not deleted" do
    recording = Recording.create_with_document!({ title: "v1", body: "body1" })

    assert_raises(Recording::NotDeletedRecordingError) do
      recording.restore_with_event!
    end
  end
end
