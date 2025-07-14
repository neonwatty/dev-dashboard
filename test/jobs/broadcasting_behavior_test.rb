require "test_helper"

class BroadcastingBehaviorTest < ActiveJob::TestCase
  include ActionCable::TestHelper

  def setup
    @source = sources(:huggingface_forum)
    @reddit_source = sources(:machine_learning_reddit)
    @github_source = sources(:rails_github)
    @rss_source = sources(:ruby_blog_rss)
  end

  test "FetchHuggingFaceJob broadcasts status updates" do
    stub_request(:get, "#{@source.url}/latest.json")
      .to_return(
        status: 200,
        body: { topic_list: { topics: [] } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Should broadcast once when job completes
    assert_broadcasts("source_status:#{@source.id}", 1) do
      assert_broadcasts("source_status:all", 1) do
        FetchHuggingFaceJob.perform_now(@source.id)
      end
    end

    # Check the broadcast content
    broadcasts = broadcasts("source_status:#{@source.id}")
    assert_equal 1, broadcasts.size
    broadcast_html = JSON.parse(broadcasts.first)
    assert_match(/turbo-stream/, broadcast_html)
    assert_match(/ok/, broadcast_html)
  end

  test "FetchRedditJob broadcasts status updates with new count" do
    stub_request(:get, /reddit\.com\/r\/MachineLearning\/hot\.json/)
      .to_return(
        status: 200,
        body: {
          data: {
            children: [
              {
                data: {
                  id: "new_post_123",
                  title: "New ML Paper",
                  selftext: "Great new paper on transformers",
                  author: "ml_researcher",
                  created_utc: 1.hour.ago.to_i,
                  score: 100,
                  num_comments: 20,
                  permalink: "/r/MachineLearning/comments/abc123/new_ml_paper/",
                  url: "https://arxiv.org/paper.pdf",
                  subreddit: "MachineLearning",
                  stickied: false,
                  is_self: false
                }
              }
            ]
          }
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    assert_broadcasts("source_status:#{@reddit_source.id}", 2) do # One for refreshing, one for complete
      assert_broadcasts("source_status:all", 2) do
        FetchRedditJob.perform_now(@reddit_source.id)
      end
    end

    # Check final broadcast shows new item count
    @reddit_source.reload
    assert_match(/ok \(1 new\)/, @reddit_source.status)
  end

  test "job error broadcasts error status" do
    stub_request(:get, /github\.com/)
      .to_return(status: 404)

    assert_broadcasts("source_status:#{@github_source.id}", 1) do
      assert_broadcasts("source_status:all", 1) do
        FetchGithubIssuesJob.perform_now(@github_source.id)
      end
    end

    # Check error was broadcast
    @github_source.reload
    assert_match(/error/, @github_source.status)
    assert_match(/404/, @github_source.status)
  end

  test "FetchRssJob broadcasts with item count" do
    stub_request(:get, @rss_source.url)
      .to_return(
        status: 200,
        body: <<~XML
          <?xml version="1.0" encoding="UTF-8"?>
          <rss version="2.0">
            <channel>
              <title>Ruby Weekly</title>
              <item>
                <title>Ruby 3.3 Released</title>
                <link>https://rubyweekly.com/ruby-3-3</link>
                <description>New Ruby version with great features</description>
                <pubDate>#{1.hour.ago.rfc2822}</pubDate>
                <guid>ruby-3-3-release</guid>
              </item>
            </channel>
          </rss>
        XML
      )

    assert_broadcasts("source_status:#{@rss_source.id}", 1) do
      assert_broadcasts("source_status:all", 1) do
        FetchRssJob.perform_now(@rss_source.id)
      end
    end

    @rss_source.reload
    # Should show ok status (may or may not have new items depending on filtering)
    assert_match(/ok/, @rss_source.status)
  end

  test "refresh all broadcasts for each source" do
    active_sources = Source.active
    expected_broadcasts = active_sources.count

    # Each active source should get a refreshing broadcast
    assert_broadcasts("source_status:all", expected_broadcasts) do
      active_sources.each do |source|
        source.update_status_and_broadcast('refreshing...')
      end
    end
  end
end