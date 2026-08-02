require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  test "new" do
    get new_article_url
    assert_response :success
  end

  test "create records the article and redirects to its recording" do
    assert_difference [ "Article.count", "Recording.count", "Event.count" ], +1 do
      post articles_url, params: { article: { title: "a1", body: "b1", url: "https://example.com" } }
    end

    assert_redirected_to Recording.last
    assert Recording.last.article?
  end

  test "create re-renders on invalid input" do
    assert_no_difference [ "Article.count", "Recording.count" ] do
      post articles_url, params: { article: { title: "", body: "b1", url: "https://example.com" } }
    end

    assert_response :unprocessable_entity
  end
end
