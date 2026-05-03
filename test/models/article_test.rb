require "test_helper"

class ArticleTest < ActiveSupport::TestCase
  test "valid with title" do
    assert Article.new(title: "hello").valid?
  end

  test "invalid without title" do
    article = Article.new(title: nil)
    assert_not article.valid?
    assert_includes article.errors[:title], "can't be blank"
  end
end
