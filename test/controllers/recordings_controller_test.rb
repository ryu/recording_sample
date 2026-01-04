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
    assert_difference ["Document.count", "Recording.count"], +1 do
      post recordings_url, params: { document: { title: "v1", body: "body1" } }
    end
    assert_response :redirect
  end

  test "should show recording" do
    recording = Recording.create_with_document!(title: "v1", body: "body1")
    get recording_url(recording)
    assert_response :success
  end
end
