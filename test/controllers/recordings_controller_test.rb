require "test_helper"

class RecordingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get recordings_url
    assert_response :success
  end

  test "should get new" do
    get new_recording_url
    assert_response :success
  end

  test "should create recording" do
    assert_difference %w[Document.count Recording.count], +1 do
      post recordings_url, params: { document: { title: "v1", body: "body1" } }
    end
    assert_response :redirect
  end

  test "should show recording" do
    recording = Recording.create_with_document!({ title: "v1", body: "body1" }, actor_name: "web")
    get recording_url(recording)
    assert_response :success
  end

  test "events store metadata when provided" do
    recording = Recording.create_with_document!(
      { title: "v1", body: "body1" },
      actor_name: "web",
      metadata: { "source" => "test", "request_id" => "req-123" }
    )

    event = recording.events.order(:created_at).last
    assert_equal "created", event.action_type
    assert_equal "test", event.metadata["source"]
    assert_equal "req-123", event.metadata["request_id"]
  end

  test "updated event stores changed_fields for title" do
    recording = Recording.create_with_document!({ title: "v1", body: "body1" })

    recording.update_with_new_document!({ title: "v2", body: "body1" })

    last_event = recording.events.order(:created_at).last
    assert_equal "updated", last_event.action_type
    assert_equal ["title"], last_event.metadata["changed_fields"]
  end

end
