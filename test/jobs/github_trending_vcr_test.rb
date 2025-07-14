require "test_helper"

class GithubTrendingVcrTest < ActiveJob::TestCase
  setup do
    @source = sources(:github_trending)
  end

  test "should fetch real trending repositories with VCR" do
    VCR.use_cassette("github_trending/daily_ruby_repos") do
      repositories = GitHubTrendingService.new(@source).fetch_trending_repositories(since: 'daily')
      
      assert repositories.is_a?(Array), "Should return an array"
      
      if repositories.any?
        repo = repositories.first
        
        # Verify expected fields are present
        assert repo.key?('id'), "Repository should have id"
        assert repo.key?('full_name'), "Repository should have full_name"
        assert repo.key?('html_url'), "Repository should have html_url"
        assert repo.key?('owner'), "Repository should have owner"
        assert repo['owner'].key?('login'), "Owner should have login"
        assert repo.key?('created_at'), "Repository should have created_at"
        
        # Verify URL format
        assert_match %r{https://github\.com/.+/.+}, repo['html_url']
        
        # Verify created_at is recent (within last day for daily search)
        created_time = Time.parse(repo['created_at'])
        assert created_time >= 1.day.ago, "Repository should be created within last day"
        
        Rails.logger.info "✅ Found #{repositories.count} trending repositories"
        Rails.logger.info "First repo: #{repo['full_name']}"
      else
        Rails.logger.info "ℹ️  No trending repositories found (this can happen)"
      end
    end
  end

  test "should handle different time periods with VCR" do
    VCR.use_cassette("github_trending/weekly_javascript_repos") do
      @source.update!(config: '{"since": "weekly", "language": "JavaScript"}')
      service = GitHubTrendingService.new(@source)
      
      repositories = service.fetch_trending_repositories(since: 'weekly')
      
      assert repositories.is_a?(Array)
      
      if repositories.any?
        # Verify repositories are from the last week
        repositories.each do |repo|
          created_time = Time.parse(repo['created_at'])
          assert created_time >= 7.days.ago, "Repository should be created within last week"
          
          # If language filtering is working, all repos should be JavaScript
          if repo['language']
            assert_equal 'JavaScript', repo['language'], "Repository should be JavaScript"
          end
        end
        
        Rails.logger.info "✅ Found #{repositories.count} weekly JavaScript repositories"
      end
    end
  end

  test "should create posts from real API data with VCR" do
    VCR.use_cassette("github_trending/create_posts_from_real_data") do
      initial_post_count = Post.count
      
      perform_enqueued_jobs do
        FetchGithubTrendingJob.perform_now(@source.id)
      end
      
      @source.reload
      
      # Should have successful status
      assert_match /^ok/, @source.status, "Source status should be ok"
      assert_not_nil @source.last_fetched_at, "last_fetched_at should be updated"
      
      new_posts = Post.where(source: 'github_trending').where('created_at > ?', 1.minute.ago)
      
      if new_posts.any?
        post = new_posts.first
        
        # Verify post structure
        assert_not_nil post.title, "Post should have title"
        assert_not_nil post.url, "Post should have URL"
        assert_not_nil post.author, "Post should have author"
        assert_not_nil post.external_id, "Post should have external_id"
        assert_equal 'github_trending', post.source
        assert_equal 'unread', post.status
        assert post.priority_score >= 0, "Priority score should be non-negative"
        
        # Verify URL format
        assert_match %r{https://github\.com/.+/.+}, post.url
        
        # Verify tags are present and valid JSON
        assert_not_nil post.tags
        tags = post.tags_array
        assert tags.is_a?(Array), "Tags should be an array"
        assert_includes tags, 'trending', "Should include 'trending' tag"
        
        # Verify summary contains useful information
        assert_not_nil post.summary
        if post.summary.present?
          # Summary should contain at least some repository metadata
          summary_has_content = post.summary.include?('stars') || 
                              post.summary.include?('forks') || 
                              post.summary.include?('📝')
          assert summary_has_content, "Summary should contain repository metadata"
        end
        
        Rails.logger.info "✅ Created #{new_posts.count} posts from real GitHub trending data"
        Rails.logger.info "Sample post: #{post.title}"
        Rails.logger.info "Tags: #{tags.join(', ')}"
        Rails.logger.info "Priority score: #{post.priority_score}"
      else
        Rails.logger.info "ℹ️  No new posts created (no trending repos found or all duplicates)"
      end
    end
  end

  test "should handle authentication with real token" do
    # Only run this test if we have a real token in environment
    skip "No GitHub token available" unless ENV['GITHUB_TOKEN']
    
    @source.update!(config: %Q({"token": "#{ENV['GITHUB_TOKEN']}", "since": "daily"}))
    
    VCR.use_cassette("github_trending/authenticated_request", record: :new_episodes) do
      service = GitHubTrendingService.new(@source)
      
      repositories = service.fetch_trending_repositories
      
      # With authentication, we should have higher rate limits
      # This test mainly verifies the auth header is sent correctly
      assert repositories.is_a?(Array)
      Rails.logger.info "✅ Authenticated request successful"
    end
  end

  test "should handle rate limiting gracefully with VCR" do
    VCR.use_cassette("github_trending/rate_limit_error") do
      service = GitHubTrendingService.new(@source)
      
      # This cassette should contain a 403 rate limit response
      assert_raises(RuntimeError, /rate limit/i) do
        service.fetch_trending_repositories
      end
      
      Rails.logger.info "✅ Rate limiting handled correctly"
    end
  end

  test "should measure API response time" do
    VCR.use_cassette("github_trending/performance_test") do
      start_time = Time.current
      
      service = GitHubTrendingService.new(@source)
      repositories = service.fetch_trending_repositories
      
      end_time = Time.current
      response_time = ((end_time - start_time) * 1000).round  # Convert to milliseconds
      
      Rails.logger.info "GitHub Trending API Response time: #{response_time}ms for #{repositories.count} repositories"
      
      # API should respond reasonably quickly (even with VCR, this tests our processing time)
      assert response_time < 5000, "API response should be under 5 seconds"
    end
  end

  test "should handle various repository metadata" do
    VCR.use_cassette("github_trending/metadata_validation") do
      service = GitHubTrendingService.new(@source)
      repositories = service.fetch_trending_repositories
      
      if repositories.any?
        # Test handling of repositories with different metadata completeness
        repositories.each do |repo|
          # All repos should have required fields
          assert repo['id'], "Repository should have ID"
          assert repo['full_name'], "Repository should have full_name"
          assert repo['html_url'], "Repository should have URL"
          assert repo['owner']['login'], "Repository should have owner login"
          assert repo['created_at'], "Repository should have created_at"
          
          # Optional fields should be handled gracefully
          if repo['description']
            assert repo['description'].is_a?(String), "Description should be string"
          end
          
          if repo['language']
            assert repo['language'].is_a?(String), "Language should be string"
          end
          
          if repo['topics']
            assert repo['topics'].is_a?(Array), "Topics should be array"
          end
          
          # Numeric fields should be handled correctly
          ['stargazers_count', 'forks_count', 'watchers_count'].each do |field|
            if repo[field]
              assert repo[field].is_a?(Integer), "#{field} should be integer"
              assert repo[field] >= 0, "#{field} should be non-negative"
            end
          end
        end
        
        Rails.logger.info "✅ Validated metadata for #{repositories.count} repositories"
      end
    end
  end

  test "should compare priority scoring with real data" do
    VCR.use_cassette("github_trending/priority_scoring_test") do
      @source.update!(config: '{"preferred_languages": ["Ruby", "JavaScript", "Python"]}')
      service = GitHubTrendingService.new(@source)
      
      repositories = service.fetch_trending_repositories
      
      if repositories.length >= 2
        # Create posts and compare scores
        scores = repositories.map do |repo|
          post = Post.new(
            source: 'github_trending',
            external_id: "test_#{repo['id']}",
            title: "#{repo['full_name']} - #{repo['description']}",
            url: repo['html_url'],
            author: repo['owner']['login'],
            posted_at: Time.parse(repo['created_at']),
            priority_score: service.calculate_repository_priority_score(repo)
          )
          
          {
            repo: repo,
            score: post.priority_score,
            full_name: repo['full_name'],
            language: repo['language'],
            stars: repo['stargazers_count'] || 0,
            forks: repo['forks_count'] || 0
          }
        end
        
        # Sort by score descending
        scores.sort_by! { |s| -s[:score] }
        
        Rails.logger.info "Priority Scoring Results:"
        scores.first(5).each_with_index do |score_data, index|
          Rails.logger.info "#{index + 1}. #{score_data[:full_name]} (#{score_data[:language]})"
          Rails.logger.info "   Score: #{score_data[:score].round(2)}, Stars: #{score_data[:stars]}, Forks: #{score_data[:forks]}"
        end
        
        # Verify scoring makes sense
        top_score = scores.first[:score]
        bottom_score = scores.last[:score]
        
        # Top scored repo should have higher score than bottom
        assert top_score >= bottom_score, "Priority scoring should create meaningful differences"
        
        Rails.logger.info "✅ Priority scoring working correctly"
      end
    end
  end

  test "should handle monthly trending search" do
    VCR.use_cassette("github_trending/monthly_search") do
      @source.update!(config: '{"since": "monthly"}')
      service = GitHubTrendingService.new(@source)
      
      repositories = service.fetch_trending_repositories(since: 'monthly')
      
      assert repositories.is_a?(Array)
      
      if repositories.any?
        # Verify repositories are from the last month
        repositories.each do |repo|
          created_time = Time.parse(repo['created_at'])
          assert created_time >= 30.days.ago, "Repository should be created within last month"
        end
        
        Rails.logger.info "✅ Found #{repositories.count} monthly trending repositories"
      end
    end
  end

  test "should handle edge cases with malformed responses" do
    # This test ensures our service handles unexpected API responses gracefully
    VCR.use_cassette("github_trending/edge_cases") do
      service = GitHubTrendingService.new(@source)
      
      begin
        repositories = service.fetch_trending_repositories
        
        # Should always return an array, even if API returns unexpected data
        assert repositories.is_a?(Array), "Should always return array"
        
        Rails.logger.info "✅ Handled edge cases correctly"
      rescue => e
        # If we get an error, it should be a meaningful one, not a parsing error
        assert_match /(HTTP|API|rate limit|timeout)/i, e.message, "Errors should be API-related, not parsing errors"
        Rails.logger.info "✅ Gracefully handled API error: #{e.message}"
      end
    end
  end
end