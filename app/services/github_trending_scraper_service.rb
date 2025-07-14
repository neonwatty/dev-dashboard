require 'net/http'
require 'nokogiri'
require 'json'

class GitHubTrendingScraperService
  attr_reader :source

  def initialize(source)
    @source = source
  end

  def fetch_trending_repositories(options = {})
    # Allow explicit nil to override config
    language = options.key?(:language) ? options[:language] : extract_language_from_config
    since = options[:since] || 'daily'
    
    begin
      # Build URL with parameters
      url = "https://github.com/trending"
      params = []
      params << "language=#{CGI.escape(language)}" if language.present?
      params << "since=#{since}" if since.present?
      
      full_url = params.any? ? "#{url}?#{params.join('&')}" : url
      
      Rails.logger.info "🕸️  Scraping GitHub trending from: #{full_url}"
      
      # Fetch the page
      uri = URI(full_url)
      response = Net::HTTP.get_response(uri)
      
      if response.code != '200'
        raise "Failed to fetch GitHub trending page: HTTP #{response.code}"
      end
      
      # Parse the HTML
      doc = Nokogiri::HTML(response.body)
      repositories = []
      
      # Find all repository articles
      doc.css('article.Box-row').each do |article|
        begin
          repo_data = extract_repository_data(article)
          repositories << repo_data if repo_data
        rescue => e
          Rails.logger.warn "Failed to parse repository: #{e.message}"
        end
      end
      
      Rails.logger.info "✅ Successfully scraped #{repositories.length} trending repositories"
      repositories
      
    rescue => e
      Rails.logger.error "Error scraping GitHub trending: #{e.message}"
      raise e
    end
  end

  def create_post_from_repository(repo)
    # Use external_id that matches the repo structure from scraping
    external_id = "#{repo[:author]}/#{repo[:name]}"
    
    post = Post.find_or_initialize_by(
      source: @source.name,
      external_id: external_id
    )
    
    return false unless post.new_record?

    post.assign_attributes(
      title: "#{repo[:author]}/#{repo[:name]} - #{repo[:description]}",
      url: repo[:url],
      author: repo[:author],
      posted_at: Time.current, # Trending repos don't have specific creation time
      summary: build_repository_summary(repo),
      tags: extract_repository_tags(repo),
      status: 'unread',
      priority_score: calculate_repository_priority_score(repo)
    )
    
    post.save!
    true
  rescue => e
    Rails.logger.error "Error creating post from scraped repo #{repo[:name]}: #{e.message}"
    false
  end

  def calculate_repository_priority_score(repo)
    score = 0
    
    # Base score from total stars
    total_stars = repo[:stars] || 0
    score += Math.log10([total_stars, 1].max) * 10
    
    # Major boost for stars today (this is what makes it trending!)
    stars_today = repo[:stars_today] || 0
    score += stars_today * 0.5  # Each star today is worth 0.5 points
    
    # Boost for forks
    forks = repo[:forks] || 0
    score += Math.log10([forks, 1].max) * 5
    
    # Boost for language preferences
    config = @source.config_hash
    preferred_languages = config['preferred_languages'] || []
    if preferred_languages.include?(repo[:language])
      score += 20
    end
    
    # Boost based on ranking (higher ranked = more trending)
    if repo[:rank]
      score += [26 - repo[:rank], 0].max * 2  # Top 25 get boost
    end
    
    score
  end

  private

  def extract_repository_data(article)
    # Extract repository link and name
    repo_link = article.at_css('h2 a')
    return nil unless repo_link
    
    href = repo_link['href']
    full_name = href.gsub(/^\//, '')
    author, name = full_name.split('/', 2)
    
    # Extract description
    description_elem = article.at_css('p.col-9')
    description = description_elem&.text&.strip || ''
    
    # Extract language
    language_elem = article.at_css('span[itemprop="programmingLanguage"]')
    language = language_elem&.text&.strip
    
    # Extract stars and forks
    stats_links = article.css('a.Link--muted')
    stars = 0
    forks = 0
    
    stats_links.each do |link|
      svg = link.at_css('svg')
      next unless svg
      
      if svg['class']&.include?('octicon-star')
        stars = parse_number(link.text.strip)
      elsif svg['class']&.include?('octicon-repo-forked')
        forks = parse_number(link.text.strip)
      end
    end
    
    # Extract stars today - this is the key trending metric!
    stars_today_elem = article.at_css('span.float-sm-right')
    stars_today = 0
    if stars_today_elem
      stars_today_text = stars_today_elem.text.strip
      if stars_today_text =~ /(\d+(?:,\d+)*)\s+stars?\s+today/
        stars_today = parse_number($1)
      end
    end
    
    # Get the ranking (position on the page)
    rank = article['data-position']&.to_i || 0
    
    {
      author: author,
      name: name,
      full_name: full_name,
      url: "https://github.com/#{full_name}",
      description: description,
      language: language,
      stars: stars,
      forks: forks,
      stars_today: stars_today,
      rank: rank
    }
  end

  def parse_number(text)
    # Convert "1,234" to 1234
    text.gsub(',', '').to_i
  end

  def extract_language_from_config
    config = @source.config_hash
    config['language'] || config['preferred_languages']&.first
  end

  def build_repository_summary(repo)
    summary_parts = []
    
    summary_parts << repo[:description] if repo[:description].present?
    
    if repo[:stars_today] && repo[:stars_today] > 0
      summary_parts << "🔥 #{repo[:stars_today]} stars today"
    end
    
    if repo[:stars] && repo[:stars] > 0
      summary_parts << "⭐ #{repo[:stars]} total stars"
    end
    
    if repo[:forks] && repo[:forks] > 0
      summary_parts << "🍴 #{repo[:forks]} forks"
    end
    
    summary_parts << "📝 #{repo[:language]}" if repo[:language].present?
    
    summary_parts.join(' | ')
  end

  def extract_repository_tags(repo)
    tags = []
    
    # Add language as tag
    tags << repo[:language] if repo[:language].present?
    
    # Always mark as trending
    tags << 'trending'
    
    # Mark based on today's performance
    if repo[:stars_today]
      tags << 'hot' if repo[:stars_today] >= 100
      tags << 'rising' if repo[:stars_today].between?(20, 99)
    end
    
    # Mark by popularity
    tags << 'popular' if repo[:stars].to_i > 1000
    
    # Mark by rank
    tags << 'top-10' if repo[:rank].to_i.between?(1, 10)
    
    tags.compact.uniq.to_json
  end
end