require "test_helper"

class RestorationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @recording = Recording.create_for(Document.new(title: "v1", body: "body1"))
  end

  test "create restores a deleted recording" do
    @recording.soft_delete

    assert_difference "@recording.events.count", +1 do
      post recording_restoration_url(@recording)
    end

    assert_redirected_to @recording
    assert_not @recording.reload.deleted?
    assert @recording.events.recent.first.was_restored?
  end

  test "create 404s when the recording is not deleted" do
    post recording_restoration_url(@recording)

    assert_response :not_found
  end
end
