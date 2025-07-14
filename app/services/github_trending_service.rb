require 'net/http'
require 'json'

class GitHubTrendingService
  attr_reader :source

  def initialize(source)
    @source = source
  end

  def fetch_trending_repositories(options = {})
    language = options[:language] || extract_language_from_config
    since = options[:since] || 'daily' # daily, weekly, monthly
    
    begin
      # GitHub doesn't have an official trending API, but we can use the search API
      # to approximate trending by searching for recently created repos with high stars
      api_url = "https://api.github.com/search/repositories"
      uri = URI(api_url)
      
      # Build query for trending-like results
      # GitHub trending includes repos with recent activity, not just newly created ones
      # We'll use multiple strategies to find trending repositories
      
      queries = build_trending_queries(since, language)
      all_repos = []
      
      # Execute multiple queries to get a diverse set of trending repos
      queries.each do |query_config|
        params = {
          'q' => query_config[:query],
          'sort' => query_config[:sort],
          'order' => 'desc',
          'per_page' => '15'  # Fewer per query, more queries
        }
        
        uri.query = URI.encode_www_form(params)
        request = Net::HTTP::Get.new(uri)
        request['Accept'] = 'application/vnd.github.v3+json'
        request['User-Agent'] = 'DevDashboard/1.0'
        
        config = @source.config_hash
        if config['token'].present?
          request['Authorization'] = "token #{config['token']}"
        end
        
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end
        
        if response.code == '200'
          data = JSON.parse(response.body)
          repos = data['items'] || []
          all_repos.concat(repos)
        else
          Rails.logger.warn "Query failed: #{query_config[:query]} - #{response.code}"
        end
      end
      
      # Remove duplicates and limit results
      unique_repos = all_repos.uniq { |repo| repo['id'] }
      
      # Sort by a trending score that considers multiple factors
      scored_repos = unique_repos.map do |repo|
        repo['trending_score'] = calculate_trending_score(repo, since)
        repo
      end
      
      # Return top repositories sorted by trending score
      return scored_repos.sort_by { |repo| -repo['trending_score'] }.first(30)
    rescue => e
      Rails.logger.error "Error fetching GitHub trending: #{e.message}"
      raise e
    end
  end

  def create_post_from_repository(repo)
    post = Post.find_or_initialize_by(
      source: @source.name,
      external_id: repo['id'].to_s
    )
    
    return false unless post.new_record?

    post.assign_attributes(
      title: "#{repo['full_name']} - #{repo['description']}",
      url: repo['html_url'],
      author: repo['owner']['login'],
      posted_at: Time.parse(repo['created_at']),
      summary: build_repository_summary(repo),
      tags: extract_repository_tags(repo),
      status: 'unread',
      priority_score: calculate_repository_priority_score(repo)
    )
    
    post.save!
    true
  rescue => e
    Rails.logger.error "Error creating post from GitHub trending repo #{repo['id']}: #{e.message}"
    false
  end

  def calculate_repository_priority_score(repo)
    score = 0
    
    # Base score from repository metrics
    score += (repo['stargazers_count'] || 0) * 0.1
    score += (repo['forks_count'] || 0) * 0.2
    score += (repo['watchers_count'] || 0) * 0.1
    
    # Boost for recently created repositories that are gaining traction
    days_old = (Time.current - Time.parse(repo['created_at'])) / 1.day
    if days_old <= 7
      score += [10 - days_old, 0].max * 2.0
    end
    
    # Boost for repositories with good documentation
    score += 3.0 if repo['description'].present? && repo['description'].length > 20
    
    # Boost for specific languages from source config
    config = @source.config_hash
    preferred_languages = config['preferred_languages'] || []
    if preferred_languages.include?(repo['language'])
      score += 5.0
    end
    
    # Boost for repositories with specific topics
    helpful_topics = ['beginner-friendly', 'good-first-issues', 'hacktoberfest', 'open-source']
    if repo['topics'].present?
      matching_topics = repo['topics'] & helpful_topics
      score += matching_topics.count * 2.0
    end
    
    score
  end

  def build_trending_queries(since, language)
    # Build multiple search queries to capture different types of trending repos
    language_filter = language.present? ? " language:#{language}" : ""
    
    case since
    when 'weekly'
      date_7_days = (Date.current - 7.days).strftime('%Y-%m-%d')
      date_30_days = (Date.current - 30.days).strftime('%Y-%m-%d')
      [
        # Recently created repos with good traction
        { query: "created:>#{date_7_days} stars:>5#{language_filter}", sort: "stars" },
        # Older repos with recent pushes and many stars
        { query: "pushed:>#{date_7_days} stars:>100#{language_filter}", sort: "updated" },
        # Very popular repos updated recently
        { query: "pushed:>#{date_30_days} stars:>1000#{language_filter}", sort: "stars" }
      ]
    when 'monthly'
      date_30_days = (Date.current - 30.days).strftime('%Y-%m-%d')
      date_90_days = (Date.current - 90.days).strftime('%Y-%m-%d')
      [
        # Recently created repos
        { query: "created:>#{date_30_days} stars:>3#{language_filter}", sort: "stars" },
        # Active repos with good star counts
        { query: "pushed:>#{date_30_days} stars:>50#{language_filter}", sort: "updated" },
        # Popular repos with recent activity
        { query: "pushed:>#{date_90_days} stars:>500#{language_filter}", sort: "stars" }
      ]
    else # daily
      date_1_day = (Date.current - 1.day).strftime('%Y-%m-%d')
      date_7_days = (Date.current - 7.days).strftime('%Y-%m-%d')
      [
        # Brand new repos gaining stars
        { query: "created:>#{date_1_day} stars:>1#{language_filter}", sort: "stars" },
        # Recently active popular repos
        { query: "pushed:>#{date_1_day} stars:>50#{language_filter}", sort: "updated" },
        # Established repos with recent activity
        { query: "pushed:>#{date_7_days} stars:>200#{language_filter}", sort: "stars" }
      ]
    end
  end

  def calculate_trending_score(repo, since)
    # Calculate a trending score based on multiple factors
    score = 0
    
    # Base score from stars (logarithmic to avoid huge repos dominating)
    stars = repo['stargazers_count'] || 0
    score += Math.log10([stars, 1].max) * 10
    
    # Boost for recent creation
    created_at = Time.parse(repo['created_at'])
    days_old = (Time.current - created_at) / 1.day
    
    case since
    when 'daily'
      # Big boost for very new repos
      score += [7 - days_old, 0].max * 3 if days_old <= 7
    when 'weekly'
      score += [30 - days_old, 0].max * 1 if days_old <= 30
    when 'monthly'
      score += [90 - days_old, 0].max * 0.5 if days_old <= 90
    end
    
    # Boost for good engagement ratios
    forks = repo['forks_count'] || 0
    watchers = repo['watchers_count'] || 0
    
    # Good fork-to-star ratio indicates community engagement
    if stars > 0
      fork_ratio = forks.to_f / stars
      score += fork_ratio * 10 if fork_ratio.between?(0.05, 0.3)
    end
    
    # Boost for language preferences
    config = @source.config_hash
    preferred_languages = config['preferred_languages'] || []
    if preferred_languages.include?(repo['language'])
      score += 15
    end
    
    # Boost for helpful topics
    helpful_topics = ['beginner-friendly', 'good-first-issues', 'hacktoberfest', 'awesome', 'tutorial']
    if repo['topics'].present?
      matching_topics = repo['topics'] & helpful_topics
      score += matching_topics.count * 3
    end
    
    # Boost for good descriptions (indicates quality)
    if repo['description'].present? && repo['description'].length > 20
      score += 5
    end
    
    # Slight boost for recent pushes (indicates active development)
    if repo['pushed_at'].present?
      pushed_at = Time.parse(repo['pushed_at'])
      days_since_push = (Time.current - pushed_at) / 1.day
      score += [30 - days_since_push, 0].max * 0.1 if days_since_push <= 30
    end
    
    score
  end

  def extract_language_from_config
    config = @source.config_hash
    config['language'] || config['preferred_languages']&.first
  end

  def build_repository_summary(repo)
    summary_parts = []
    
    summary_parts << repo['description'] if repo['description'].present?
    
    if repo['stargazers_count'] && repo['stargazers_count'] > 0
      summary_parts << "⭐ #{repo['stargazers_count']} stars"
    end
    
    if repo['forks_count'] && repo['forks_count'] > 0
      summary_parts << "🍴 #{repo['forks_count']} forks"
    end
    
    summary_parts << "📝 #{repo['language']}" if repo['language'].present?
    
    summary_parts.join(' | ')
  end

  def extract_repository_tags(repo)
    tags = []
    
    # Add language as tag
    tags << repo['language'] if repo['language'].present?
    
    # Add topics as tags
    tags.concat(repo['topics']) if repo['topics'].present?
    
    # Add repository type indicators
    tags << 'trending' # Always mark as trending
    tags << 'new-repo' if repo['created_at'].present? && (Time.current - Time.parse(repo['created_at'])) < 7.days
    tags << 'popular' if repo['stargazers_count'].to_i > 100
    
    # Add license information
    tags << "license:#{repo['license']['key']}" if repo['license'].present?
    
    tags.compact.uniq.to_json
  end

  def handle_api_error(response)
    error_msg = "HTTP #{response.code}"
    case response.code
    when '403'
      error_msg += " - Rate limit exceeded or authentication required"
    when '422'
      error_msg += " - Invalid search query or parameters"
    end
    
    raise error_msg
  end
end