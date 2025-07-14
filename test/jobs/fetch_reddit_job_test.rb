require "test_helper"

class FetchRedditJobTest < ActiveJob::TestCase
  setup do
    @source = sources(:machine_learning_reddit)
    
    # Generate unique IDs for each test run
    @post1_id = "reddit_test123_#{Time.now.to_i}_#{rand(1000)}"
    @post2_id = "reddit_test456_#{Time.now.to_i}_#{rand(1000)}"
    
    # Sample Reddit API response
    @reddit_response = {
      "data" => {
        "children" => [
          {
            "data" => {
              "id" => @post1_id,
              "title" => "New AI Research Paper",
              "selftext" => "This is a breakthrough in machine learning...",
              "author" => "researcher123",
              "created_utc" => 1.hour.ago.to_i,
              "permalink" => "/r/MachineLearning/comments/test123/new_ai_research_paper/",
              "ups" => 150,
              "downs" => 5,
              "score" => 145,
              "num_comments" => 25,
              "upvote_ratio" => 0.97,
              "is_self" => true,
              "stickied" => false,
              "link_flair_text" => "Research"
            }
          },
          {
            "data" => {
              "id" => @post2_id,
              "title" => "Cool ML Research Project",
              "selftext" => "",
              "url" => "https://github.com/user/ml-project",
              "author" => "developer456",
              "created_utc" => 2.hours.ago.to_i,
              "permalink" => "/r/MachineLearning/comments/test456/cool_ml_project/",
              "ups" => 75,
              "downs" => 2,
              "score" => 73,
              "num_comments" => 12,
              "upvote_ratio" => 0.95,
              "is_self" => false,
              "stickied" => false,
              "link_flair_text" => "Project"
            }
          }
        ]
      }
    }
  end

  test "should extract subreddit from URL correctly" do
    job = FetchRedditJob.new
    
    # Test various URL formats
    assert_equal "MachineLearning", job.send(:extract_subreddit_from_url, "https://www.reddit.com/r/MachineLearning")
    assert_equal "MachineLearning", job.send(:extract_subreddit_from_url, "https://www.reddit.com/r/MachineLearning/")
    assert_equal "MachineLearning", job.send(:extract_subreddit_from_url, "https://www.reddit.com/r/MachineLearning/hot")
    assert_equal "programming", job.send(:extract_subreddit_from_url, "https://reddit.com/r/programming")
    assert_nil job.send(:extract_subreddit_from_url, "https://reddit.com/invalid")
  end

  test "should fetch and process Reddit posts" do
    # Mock the Reddit API call
    stub_request(:get, /reddit\.com\/r\/MachineLearning\/hot\.json/)
      .to_return(status: 200, body: @reddit_response.to_json, headers: { 'Content-Type' => 'application/json' })
    
    assert_difference("Post.count", 2) do
      FetchRedditJob.perform_now(@source.id)
    end
    
    # Check that posts were created with correct data
    post = Post.where(title: "New AI Research Paper").last
    assert_not_nil post
    assert_equal "New AI Research Paper", post.title
    assert_equal "researcher123", post.author
    assert_includes post.tags, "subreddit:MachineLearning"
    assert_includes post.tags, "reddit"
    assert_includes post.tags, "Research"
    assert_includes post.tags, "text-post"
    assert_equal "https://www.reddit.com/r/MachineLearning/comments/test123/new_ai_research_paper/", post.url
    
    # Check second post
    post2 = Post.where(title: "Cool ML Research Project").last
    assert_not_nil post2
    assert_equal "Cool ML Research Project", post2.title
    assert_includes post2.tags, "github"
    assert_equal "https://github.com/user/ml-project", post2.summary
  end

  test "should handle keyword filtering" do
    # Mock the Reddit API call
    stub_request(:get, /reddit\.com\/r\/MachineLearning\/hot\.json/)
      .to_return(status: 200, body: @reddit_response.to_json, headers: { 'Content-Type' => 'application/json' })
    
    # Update source config to only include posts with "breakthrough" keyword
    @source.update!(config: '{"keywords": ["breakthrough"]}')
    
    assert_difference("Post.count", 1) do # Only one post should match
      FetchRedditJob.perform_now(@source.id)
    end
    
    # Only the research post should be created (it contains "breakthrough" in summary)
    assert Post.exists?(title: "New AI Research Paper")
    assert_not Post.exists?(title: "Cool ML Research Project")
  end

  test "should handle stickied posts" do
    # Add a stickied post to the response
    stickied_response = @reddit_response.deep_dup
    stickied_response["data"]["children"][0]["data"]["stickied"] = true
    
    stub_request(:get, /reddit\.com\/r\/MachineLearning\/hot\.json/)
      .to_return(status: 200, body: stickied_response.to_json, headers: { 'Content-Type' => 'application/json' })
    
    assert_difference("Post.count", 1) do # Only non-stickied post should be created
      FetchRedditJob.perform_now(@source.id)
    end
    
    # Only the non-stickied post should be created
    assert_not Post.exists?(title: "New AI Research Paper") # This was stickied
    assert Post.exists?(title: "Cool ML Research Project")
  end

  test "should update existing posts" do
    # Create existing post
    existing_post = Post.create!(
      source: @source.name,
      external_id: @post1_id,
      title: "Old Title",
      summary: "Old content",
      url: "https://old-url.com",
      author: "old_author",
      posted_at: 1.day.ago,
      priority_score: 1.0,
      tags: ["old_tag"],
      status: 'unread'
    )
    
    stub_request(:get, /reddit\.com\/r\/MachineLearning\/hot\.json/)
      .to_return(status: 200, body: @reddit_response.to_json, headers: { 'Content-Type' => 'application/json' })
    
    # Should update one existing post and create one new post
    assert_difference("Post.count", 1) do
      FetchRedditJob.perform_now(@source.id)
    end
    
    # Check that existing post was updated
    existing_post.reload
    assert_equal "New AI Research Paper", existing_post.title
    assert_equal "researcher123", existing_post.author
    assert_includes existing_post.tags, "subreddit:MachineLearning"
  end

  test "should handle API errors gracefully" do
    # Mock API failure
    stub_request(:get, /reddit\.com\/r\/MachineLearning\/hot\.json/)
      .to_return(status: 500, body: "Internal Server Error")
    
    assert_no_difference("Post.count") do
      FetchRedditJob.perform_now(@source.id)
    end
    
    # Check that source status was updated
    @source.reload
    assert_match(/error/, @source.status)
  end

  test "should handle invalid subreddit URL" do
    @source.update!(url: "https://invalid-url.com")
    
    assert_no_difference("Post.count") do
      FetchRedditJob.perform_now(@source.id)
    end
    
    # Check that source status was updated
    @source.reload
    assert_equal "error: invalid subreddit URL", @source.status
  end

  test "should process all active Reddit sources when no source_id provided" do
    # Create another active Reddit source with unique URL
    reddit_source2 = Source.create!(
      name: "Ruby Reddit",
      source_type: "reddit",
      url: "https://www.reddit.com/r/ruby",
      config: '{}',
      active: true
    )
    
    # Create a different response for Ruby subreddit
    ruby_response = {
      "data" => {
        "children" => [
          {
            "data" => {
              "id" => "ruby_post_1",
              "title" => "Ruby 3.4 Released",
              "selftext" => "New features in Ruby 3.4...",
              "author" => "rubyist",
              "created_utc" => 30.minutes.ago.to_i,
              "permalink" => "/r/ruby/comments/ruby1/ruby_34_released/",
              "ups" => 200,
              "score" => 195,
              "num_comments" => 45,
              "is_self" => true,
              "stickied" => false
            }
          },
          {
            "data" => {
              "id" => "ruby_post_2",
              "title" => "Rails 8 Performance Tips",
              "selftext" => "How to optimize Rails 8 apps...",
              "author" => "railsdev",
              "created_utc" => 1.hour.ago.to_i,
              "permalink" => "/r/ruby/comments/ruby2/rails_8_performance/",
              "ups" => 150,
              "score" => 148,
              "num_comments" => 30,
              "is_self" => true,
              "stickied" => false
            }
          }
        ]
      }
    }
    
    # Mock API calls for both sources
    stub_request(:get, /reddit\.com\/r\/MachineLearning\/hot\.json/)
      .to_return(status: 200, body: @reddit_response.to_json, headers: { 'Content-Type' => 'application/json' })
    
    stub_request(:get, /reddit\.com\/r\/ruby\/hot\.json/)
      .to_return(status: 200, body: ruby_response.to_json, headers: { 'Content-Type' => 'application/json' })
    
    # Should process both sources
    assert_difference("Post.count", 4) do # 2 posts from each source
      FetchRedditJob.perform_now
    end
  end
end