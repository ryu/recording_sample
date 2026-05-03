require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  test "valid with title" do
    assert Document.new(title: "hello").valid?
  end

  test "invalid without title" do
    doc = Document.new(title: nil)
    assert_not doc.valid?
    assert_includes doc.errors[:title], "can't be blank"
  end
end
