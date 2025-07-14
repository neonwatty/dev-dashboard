require "test_helper"
require_relative "../../app/services/github_trending_scraper_service"

class GitHubTrendingScraperServiceTest < ActiveSupport::TestCase
  setup do
    @source = sources(:github_trending)
    @service = GitHubTrendingScraperService.new(@source)
  end

  test "should initialize with source" do
    assert_equal @source, @service.source
  end

  test "should handle successful scraping" do
    # Mock HTML response that looks like GitHub trending page
    html_response = <<~HTML
      <article class="Box-row">
        <h2><a href="/test/awesome-repo">test/awesome-repo</a></h2>
        <p class="col-9">An awesome test repository</p>
        <span itemprop="programmingLanguage">Ruby</span>
        <a class="Link--muted">
          <svg class="octicon-star"></svg>
          1,500
        </a>
        <a class="Link--muted">
          <svg class="octicon-repo-forked"></svg>
          300
        </a>
        <span class="float-sm-right">100 stars today</span>
      </article>
    HTML

    stub_request(:get, /github\.com\/trending/)
      .to_return(status: 200, body: html_response)

    repositories = @service.fetch_trending_repositories
    
    assert_equal 1, repositories.length
    repo = repositories.first
    
    assert_equal 'test', repo[:author]
    assert_equal 'awesome-repo', repo[:name]
    assert_equal 'An awesome test repository', repo[:description]
    assert_equal 'Ruby', repo[:language]
    assert_equal 1500, repo[:stars]
    assert_equal 300, repo[:forks]
    assert_equal 100, repo[:stars_today]
  end

  test "should handle missing optional fields" do
    # HTML without some fields
    html_response = <<~HTML
      <article class="Box-row">
        <h2><a href="/minimal/repo">minimal/repo</a></h2>
        <a class="Link--muted">
          <svg class="octicon-star"></svg>
          50
        </a>
      </article>
    HTML

    stub_request(:get, /github\.com\/trending/)
      .to_return(status: 200, body: html_response)

    repositories = @service.fetch_trending_repositories
    
    assert_equal 1, repositories.length
    repo = repositories.first
    
    assert_equal 'minimal', repo[:author]
    assert_equal 'repo', repo[:name]
    assert_equal '', repo[:description]
    assert_nil repo[:language]
    assert_equal 50, repo[:stars]
    assert_equal 0, repo[:forks]
    assert_equal 0, repo[:stars_today]
  end

  test "should build URL with language parameter" do
    expected_url = "https://github.com/trending?language=ruby&since=daily"
    
    stub_request(:get, expected_url)
      .to_return(status: 200, body: "<html></html>")

    @source.update!(config: '{"language": "ruby"}')
    @service = GitHubTrendingScraperService.new(@source)
    
    repositories = @service.fetch_trending_repositories(since: 'daily')
    
    # WebMock will verify the correct URL was called
    assert_equal 0, repositories.length  # Empty HTML response
  end

  test "should handle HTTP errors" do
    stub_request(:get, /github\.com\/trending/)
      .to_return(status: 503, body: "Service Unavailable")

    assert_raises(RuntimeError, /Failed to fetch GitHub trending page: HTTP 503/) do
      @service.fetch_trending_repositories
    end
  end

  test "should create post from scraped repository data" do
    repo_data = {
      author: 'test',
      name: 'scraped-repo',
      full_name: 'test/scraped-repo',
      url: 'https://github.com/test/scraped-repo',
      description: 'A scraped repository',
      language: 'Python',
      stars: 1001,
      forks: 200,
      stars_today: 150,
      rank: 3
    }

    assert_difference('Post.count', 1) do
      result = @service.create_post_from_repository(repo_data)
      assert result
    end

    post = Post.find_by(external_id: 'test/scraped-repo', source: @source.name)
    assert_not_nil post
    assert_equal 'test/scraped-repo - A scraped repository', post.title
    assert_includes post.summary, '🔥 150 stars today'
    assert_includes post.summary, '⭐ 1001 total stars'
    
    tags = post.tags_array
    assert_includes tags, 'Python'
    assert_includes tags, 'trending'
    assert_includes tags, 'hot'  # Because 150 stars today > 100
    assert_includes tags, 'popular'  # Because 1001 stars > 1000
    assert_includes tags, 'top-10'  # Because rank = 3
  end

  test "should calculate priority score correctly for scraped data" do
    high_trending_repo = {
      stars: 5000,
      stars_today: 500,  # Very hot!
      forks: 1000,
      language: 'Ruby',  # Preferred language
      rank: 1
    }

    low_trending_repo = {
      stars: 100,
      stars_today: 5,
      forks: 10,
      language: 'PHP',
      rank: 25
    }

    high_score = @service.calculate_repository_priority_score(high_trending_repo)
    low_score = @service.calculate_repository_priority_score(low_trending_repo)

    # High trending should have much higher score
    assert high_score > low_score
    
    # Stars today should contribute significantly
    # 500 stars * 0.5 = 250 points just from today's stars
    assert high_score > 250
  end

  test "should handle network errors gracefully" do
    stub_request(:get, /github\.com\/trending/)
      .to_raise(Timeout::Error.new("Connection timeout"))

    assert_raises(Timeout::Error) do
      @service.fetch_trending_repositories
    end
  end

  test "should parse numbers with commas correctly" do
    # Test the private parse_number method
    assert_equal 1234, @service.send(:parse_number, "1,234")
    assert_equal 1234567, @service.send(:parse_number, "1,234,567")
    assert_equal 123, @service.send(:parse_number, "123")
  end
end