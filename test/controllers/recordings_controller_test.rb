require "test_helper"

class RecordingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @recording = Recording.create_for Document.new(title: "v1", body: "body1"),
      actor_name: "web", metadata: { source: "web" }
  end

  test "index lists active recordings only" do
    deleted = Recording.create_for(Document.new(title: "gone", body: "b")).tap(&:soft_delete)

    get recordings_url

    assert_response :success
    assert_select "a[href=?]", recording_path(@recording)
    assert_select "a[href=?]", recording_path(deleted), false
  end

  test "show renders the history" do
    get recording_url(@recording)

    assert_response :success
    assert_select "li", /作成/
  end

  test "show offers restoration for a deleted recording" do
    @recording.soft_delete

    get recording_url(@recording)

    assert_response :success
    assert_select "form[action=?]", recording_restoration_path(@recording)
    assert_select "a[href=?]", edit_recording_path(@recording), false
  end

  test "update swaps in a new document and records the request" do
    assert_difference "Document.count", +1 do
      patch recording_url(@recording), params: { document: { title: "v2", body: "body1" } }
    end

    assert_redirected_to @recording

    event = @recording.events.recent.first
    assert event.was_updated?
    assert_equal [ "title" ], event.changed_fields
    assert_equal "web", event.source
    assert event.request_id.present?
  end

  test "update re-renders on invalid input" do
    assert_no_difference "Document.count" do
      patch recording_url(@recording), params: { document: { title: "", body: "body2" } }
    end

    assert_response :unprocessable_entity
  end

  test "update 404s for a deleted recording" do
    @recording.soft_delete

    patch recording_url(@recording), params: { document: { title: "v2", body: "b" } }

    assert_response :not_found
  end

  test "update 404s for an article recording" do
    article = Recording.create_for(Article.new(title: "a1", body: "b", url: "https://example.com"))

    patch recording_url(article), params: { document: { title: "v2", body: "b" } }

    assert_response :not_found
  end

  test "destroy soft deletes" do
    assert_no_difference "Recording.count" do
      delete recording_url(@recording)
    end

    assert_redirected_to recordings_path
    assert @recording.reload.deleted?
  end

  test "destroy 404s for an already deleted recording" do
    @recording.soft_delete

    delete recording_url(@recording)

    assert_response :not_found
  end
end
