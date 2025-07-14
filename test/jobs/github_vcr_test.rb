require "test_helper"
require_relative '../../app/services/github_service'

class GithubVcrTest < ActiveJob::TestCase
  setup do
    @github_source = sources(:rails_github)
    
    # Clean up any existing posts
    Post.where(source: 'github').delete_all
  end

  test "should fetch real issues from Rails repository" do
    # Temporarily remove label filtering to get any issues
    @github_source.update!(config: '{}')
    
    VCR.use_cassette("github/rails_issues_latest", 
                     record: :new_episodes,
                     re_record_interval: 7.days) do
      
      # We don't know exactly how many issues will be returned
      initial_count = Post.count
      FetchGithubIssuesJob.perform_now(@github_source.id)
      
      assert Post.count > initial_count, "Should create new posts"
      posts_created = Post.count - initial_count
      puts "\n📊 Created #{posts_created} posts from Rails GitHub repository"
      
      # Verify source was updated
      @github_source.reload
      assert_match /ok/, @github_source.status
      assert_not_nil @github_source.last_fetched_at
      
      # Verify real issue data
      posts = Post.where(source: 'github').order(posted_at: :desc)
      assert posts.count > 0
      
      # Check first post has expected fields
      first_post = posts.first
      assert first_post.title.present?, "Post should have a title"
      assert first_post.author.present?, "Post should have an author"
      assert first_post.url.include?('github.com/rails/rails'), "URL should point to Rails repository"
      assert first_post.posted_at.present?, "Post should have a posted_at date"
      assert first_post.priority_score > 0, "Post should have a priority score"
      
      # Check for reasonable data
      assert first_post.title.length > 5, "Title should be meaningful"
      assert first_post.author != 'unknown', "Should extract real author"
    end
  end

  test "should handle pagination with VCR" do
    VCR.use_cassette("github/rails_issues_paginated", 
                     record: :new_episodes) do
      
      service = GitHubService.new(@github_source)
      
      # Fetch first page
      page1_issues = service.fetch_issues(page: 1)
      assert page1_issues.is_a?(Array)
      assert page1_issues.count > 0
      
      # Fetch second page if available
      page2_issues = service.fetch_issues(page: 2)
      assert page2_issues.is_a?(Array)
      
      # Verify different content if second page has results
      if page2_issues.count > 0
        page1_ids = page1_issues.map { |issue| issue['number'] }
        page2_ids = page2_issues.map { |issue| issue['number'] }
        assert_empty (page1_ids & page2_ids), "Pages should have different issues"
      end
    end
  end

  test "should handle real API errors gracefully" do
    VCR.use_cassette("github/rails_nonexistent_repo", 
                     record: :new_episodes) do
      
      # Temporarily use an invalid repository
      original_url = @github_source.url
      @github_source.update!(url: "#{original_url}/nonexistent")
      
      assert_no_difference("Post.count") do
        FetchGithubIssuesJob.perform_now(@github_source.id)
      end
      
      @github_source.reload
      assert_match /error/, @github_source.status
    end
  end

  test "should respect API rate limits with VCR" do
    VCR.use_cassette("github/rate_limit_test", 
                     record: :new_episodes) do
      
      # Make multiple rapid requests
      3.times do |i|
        service = GitHubService.new(@github_source)
        issues = service.fetch_issues(page: i + 1)
        assert issues.is_a?(Array), "Request #{i+1} should succeed"
        
        # Small delay to be respectful even during recording
        sleep 0.5 if VCR.current_cassette.recording?
      end
    end
  end

  test "should extract all metadata fields from real responses" do
    VCR.use_cassette("github/metadata_extraction", 
                     record: :new_episodes) do
      
      service = GitHubService.new(@github_source)
      issues = service.fetch_issues
      
      # Find an issue with rich metadata
      rich_issue = issues.find { |issue| issue['labels'].present? && issue['body'].present? }
      
      if rich_issue
        success = service.create_post_from_issue(rich_issue)
        assert success, "Should create post from rich issue"
        
        post = Post.find_by(external_id: rich_issue['number'].to_s, source: 'github')
        assert_not_nil post
        
        # Verify metadata extraction
        assert_equal rich_issue['title'], post.title
        assert post.summary.present?, "Should extract body as summary"
        assert post.tags_array.count > 0, "Should extract labels as tags"
        assert_equal rich_issue['user']['login'], post.author
      end
    end
  end

  test "should handle issues with missing fields from real API" do
    VCR.use_cassette("github/missing_fields", 
                     record: :new_episodes) do
      
      service = GitHubService.new(@github_source)
      issues = service.fetch_issues
      
      # Process all issues, including those with missing fields
      created_count = 0
      issues.each do |issue|
        if service.create_post_from_issue(issue)
          created_count += 1
          
          post = Post.find_by(external_id: issue['number'].to_s, source: 'github')
          assert_not_nil post
          
          # Verify defaults for missing fields
          assert_equal [], post.tags_array if issue['labels'].nil? || issue['labels'].empty?
          assert post.url.present?, "Should always generate a URL"
        end
      end
      
      assert created_count > 0, "Should create at least some posts"
    end
  end

  test "should compare real API response times" do
    # This test helps understand API performance
    VCR.use_cassette("github/performance_test", 
                     record: :new_episodes) do
      
      start_time = Time.current
      service = GitHubService.new(@github_source)
      issues = service.fetch_issues
      end_time = Time.current
      
      response_time = end_time - start_time
      
      # Log for informational purposes
      puts "\nGitHub API Response time: #{(response_time * 1000).round}ms for #{issues.count} issues"
      
      # Reasonable expectation for API response
      assert response_time < 5.0, "API should respond within 5 seconds"
      assert issues.count > 0, "Should fetch some issues"
    end
  end

  test "should handle label filtering with VCR" do
    VCR.use_cassette("github/label_filtering", 
                     record: :new_episodes) do
      
      # Configure source with label filtering
      @github_source.update!(config: '{"labels": ["good first issue", "help wanted"]}')
      
      service = GitHubService.new(@github_source)
      issues = service.fetch_issues
      
      # All returned issues should have at least one of the specified labels
      if issues.any?
        issues.each do |issue|
          labels = (issue['labels'] || []).map { |label| label['name'].downcase }
          has_required_label = (labels & ['good first issue', 'help wanted']).any?
          assert has_required_label, "Issue #{issue['number']} should have required labels"
        end
      end
    end
  end

  test "should calculate priority scores with real data" do
    VCR.use_cassette("github/priority_scoring", 
                     record: :new_episodes) do
      
      service = GitHubService.new(@github_source)
      issues = service.fetch_issues
      
      if issues.count >= 2
        # Create posts and check their priority scores
        issue1 = issues.first
        issue2 = issues.second
        
        score1 = service.calculate_priority_score(issue1)
        score2 = service.calculate_priority_score(issue2)
        
        # Both should have positive scores
        assert score1 > 0, "First issue should have positive priority score"
        assert score2 > 0, "Second issue should have positive priority score"
        
        # Check if issues with "good first issue" label get boosted
        issue1_labels = (issue1['labels'] || []).map { |l| l['name'].downcase }
        if issue1_labels.include?('good first issue')
          assert score1 >= 5.0, "Good first issue should get 5.0 point boost"
        end
      end
    end
  end
end