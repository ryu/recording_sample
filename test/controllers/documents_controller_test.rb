require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_document_url
    assert_response :success
  end

  test "create records the document and redirects to its recording" do
    assert_difference [ "Document.count", "Recording.count", "Event.count" ], +1 do
      post documents_url, params: { document: { title: "v1", body: "body1" } }
    end

    assert_redirected_to Recording.last

    event = Recording.last.events.sole
    assert event.was_created?
    assert_equal "web", event.source
    assert event.request_id.present?
  end

  test "create re-renders on invalid input" do
    assert_no_difference [ "Document.count", "Recording.count" ] do
      post documents_url, params: { document: { title: "", body: "body1" } }
    end

    assert_response :unprocessable_entity
  end
end
