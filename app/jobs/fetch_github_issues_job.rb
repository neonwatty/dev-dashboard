class FetchGithubIssuesJob < ApplicationJob
  queue_as :default

  def perform(source_id = nil)
    if source_id
      source = Source.find(source_id)
      fetch_from_source(source)
    else
      Source.active.github.each do |source|
        fetch_from_source(source)
      end
    end
  end

  private

  def fetch_from_source(source)
    return unless source.url.include?('github.com')

    begin
      # Extract owner and repo from GitHub URL
      # Expected format: https://github.com/owner/repo
      url_parts = source.url.split('/')
      owner = url_parts[-2]
      repo = url_parts[-1]
      
      return unless owner && repo

      # Use GitHub API to get issues
      require 'net/http'
      require 'json'
      
      api_url = "https://api.github.com/repos/#{owner}/#{repo}/issues"
      uri = URI(api_url)
      
      # Add query parameters for filtering
      params = {
        'state' => 'open',
        'per_page' => '30',
        'sort' => 'updated',
        'direction' => 'desc'
      }
      
      # Add label filtering if specified in config
      config = source.config_hash
      if config['labels'].present?
        params['labels'] = config['labels'].join(',')
      end
      
      uri.query = URI.encode_www_form(params)
      
      # Create HTTP request with authentication if token provided
      request = Net::HTTP::Get.new(uri)
      request['Accept'] = 'application/vnd.github.v3+json'
      request['User-Agent'] = 'DevDashboard/1.0'
      
      if config['token'].present?
        request['Authorization'] = "token #{config['token']}"
      end
      
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end
      
      if response.code == '200'
        issues = JSON.parse(response.body)
        
        # Filter out pull requests (GitHub API includes PRs in issues endpoint)
        issues = issues.reject { |issue| issue['pull_request'] }
        
        new_posts_count = 0
        issues.each do |issue|
          if create_post_from_issue(issue, source)
            new_posts_count += 1
          end
        end
        
        source.update!(last_fetched_at: Time.current)
        status_message = new_posts_count > 0 ? "ok (#{new_posts_count} new)" : "ok"
        source.update_status_and_broadcast(status_message)
      else
        error_msg = "HTTP #{response.code}"
        if response.code == '403'
          error_msg += " - Rate limit exceeded or auth required"
        elsif response.code == '404'
          error_msg += " - Repository not found"
        end
        source.update_status_and_broadcast("error: #{error_msg}")
      end
    rescue => e
      Rails.logger.error "Error fetching from #{source.name}: #{e.message}"
      Rails.logger.error "Full error: #{e.inspect}"
      source.update_status_and_broadcast("error: #{e.message}")
    end
  end

  def create_post_from_issue(issue, source)
    post = Post.find_or_initialize_by(
      source: 'github',
      external_id: issue['number'].to_s
    )
    
    if post.new_record?
      post.title = issue['title']
      post.url = issue['html_url']
      post.author = issue['user']['login']
      post.posted_at = Time.parse(issue['created_at'])
      post.summary = truncate_text(issue['body'] || '', 300)
      post.tags = extract_labels(issue['labels'])
      post.status = 'unread'
      post.priority_score = calculate_priority_score(issue)
      post.save!
      return true
    end
    
    false
  end

  def calculate_priority_score(issue)
    score = 0
    
    # Base score from engagement
    score += (issue['comments'] || 0) * 0.5
    score += count_reactions(issue['reactions']) * 0.3
    
    # Boost for helpful labels
    helpful_labels = ['good first issue', 'help wanted', 'beginner friendly', 'easy', 'starter']
    labels = (issue['labels'] || []).map { |label| label['name'].downcase }
    score += 5.0 if (labels & helpful_labels).any?
    
    # Boost for bug reports
    score += 3.0 if labels.include?('bug')
    
    # Boost for feature requests
    score += 2.0 if labels.include?('enhancement') || labels.include?('feature')
    
    # Boost recent issues
    hours_old = (Time.current - Time.parse(issue['created_at'])) / 1.hour
    score += [10 - hours_old, 0].max * 0.3
    
    # Boost issues with recent activity
    if issue['updated_at'] && issue['updated_at'] != issue['created_at']
      hours_since_update = (Time.current - Time.parse(issue['updated_at'])) / 1.hour
      score += [5 - hours_since_update, 0].max * 0.2
    end
    
    score
  end

  def extract_labels(labels_array)
    return '[]' if labels_array.blank?
    
    labels = labels_array.map { |label| label['name'] }
    labels.to_json
  end

  def count_reactions(reactions)
    return 0 if reactions.blank?
    
    total = 0
    reactions.each do |key, value|
      total += value if key != 'url' && value.is_a?(Integer)
    end
    total
  end

  def truncate_text(text, length)
    return '' if text.blank?
    
    if text.length <= length
      text
    else
      text[0...length].rstrip + '...'
    end
  end
end