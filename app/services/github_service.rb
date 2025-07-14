require 'net/http'
require 'json'
require_relative 'concerns/post_creation'

class GitHubService
  include PostCreation
  
  attr_reader :source, :owner, :repo

  def initialize(source)
    @source = source
    parse_repository_url
  end

  def fetch_issues(options = {})
    page = options[:page] || 1
    per_page = options[:per_page] || 30
    state = options[:state] || 'open'

    return [] unless @owner && @repo

    begin
      api_url = "https://api.github.com/repos/#{@owner}/#{@repo}/issues"
      uri = URI(api_url)
      
      # Build query parameters
      params = {
        'state' => state,
        'per_page' => per_page.to_s,
        'page' => page.to_s,
        'sort' => 'updated',
        'direction' => 'desc'
      }
      
      # Add label filtering if specified in config
      config = @source.config_hash
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
        issues.reject { |issue| issue['pull_request'] }
      else
        handle_api_error(response)
      end
    rescue => e
      Rails.logger.error "Error fetching GitHub issues: #{e.message}"
      raise e
    end
  end

  def create_post_from_issue(issue)
    attributes = {
      title: issue['title'],
      url: issue['html_url'],
      author: issue['user']['login'],
      posted_at: Time.parse(issue['created_at']),
      summary: truncate_text(issue['body'] || '', 300),
      tags: extract_labels(issue['labels']),
      priority_score: calculate_priority_score(issue)
    }
    
    result = find_or_update_post(@source.name, issue['number'].to_s, attributes)
    
    # Return true only if a new post was created (for counting)
    result[:created]
  rescue => e
    Rails.logger.error "Error creating/updating post from GitHub issue #{issue['number']}: #{e.message}"
    false
  end

  def calculate_priority_score(issue)
    score = 0
    
    # Base score from engagement
    score += (issue['comments'] || 0) * 0.5
    score += count_reactions(issue['reactions']) * 0.3
    
    # Boost for helpful labels
    helpful_labels = ['good first issue', 'help wanted', 'beginner friendly', 'easy', 'starter']
    labels = extract_label_names(issue['labels'])
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
    
    # Boost for priority tags from source config
    priority_tags = @source.config_hash['priority_labels'] || []
    matching_priority_tags = labels & priority_tags.map(&:downcase)
    score += matching_priority_tags.count * 2.0
    
    score
  end

  private

  def parse_repository_url
    # Expected format: https://github.com/owner/repo
    return unless @source.url.include?('github.com')
    
    url_parts = @source.url.split('/')
    @owner = url_parts[-2]
    @repo = url_parts[-1]
    
    # Remove .git suffix if present
    @repo = @repo.sub(/\.git$/, '') if @repo
  rescue => e
    Rails.logger.error "Error parsing GitHub URL #{@source.url}: #{e.message}"
    @owner = nil
    @repo = nil
  end

  def extract_labels(labels_array)
    return '[]' if labels_array.blank?
    
    labels = labels_array.map { |label| label['name'] }
    labels.to_json
  end

  def extract_label_names(labels_array)
    return [] if labels_array.blank?
    
    labels_array.map { |label| label['name'].downcase }
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

  def handle_api_error(response)
    error_msg = "HTTP #{response.code}"
    case response.code
    when '403'
      error_msg += " - Rate limit exceeded or authentication required"
    when '404'
      error_msg += " - Repository not found or access denied"
    when '422'
      error_msg += " - Invalid repository or parameters"
    end
    
    raise error_msg
  end
end