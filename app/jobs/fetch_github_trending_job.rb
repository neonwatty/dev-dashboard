require_relative '../services/github_trending_service'
require_relative '../services/github_trending_scraper_service'

class FetchGithubTrendingJob < ApplicationJob
  queue_as :default

  def perform(source_id = nil)
    if source_id
      source = Source.find(source_id)
      fetch_from_source(source)
    else
      Source.active.auto_fetch_enabled.where(source_type: 'github_trending').each do |source|
        fetch_from_source(source)
      end
    end
  end

  private

  def fetch_from_source(source)
    return unless source.source_type == 'github_trending'
    return unless source.auto_fetch_enabled?

    begin
      # Get configuration
      config = source.config_hash
      since = config['since'] || 'daily'
      use_scraper = config['use_scraper'] == true
      
      # Use scraper if configured, otherwise use API
      if use_scraper
        Rails.logger.info "🕸️  Using scraper for #{source.name}"
        service = GitHubTrendingScraperService.new(source)
      else
        Rails.logger.info "📡 Using API for #{source.name}"
        service = GitHubTrendingService.new(source)
      end
      
      repositories = service.fetch_trending_repositories(since: since)
      
      Rails.logger.info "🔥 Found #{repositories.count} trending repositories for #{source.name}"
      repositories.each_with_index do |repo, i|
        # Handle both API format (hash with string keys) and scraper format (hash with symbol keys)
        full_name = repo['full_name'] || repo[:full_name]
        stars = repo['stargazers_count'] || repo[:stars] || 0
        Rails.logger.info "  #{i+1}. #{full_name} (⭐ #{stars} stars)"
      end
      
      new_posts_count = 0
      repositories.each do |repo|
        if service.create_post_from_repository(repo)
          new_posts_count += 1
          Rails.logger.info "✅ Created post for #{repo['full_name']}"
        else
          Rails.logger.info "⏭️  Skipped #{repo['full_name']} (duplicate)"
        end
      end
      
      source.update!(last_fetched_at: Time.current)
      status_message = new_posts_count > 0 ? "ok (#{new_posts_count} new)" : "ok"
      Rails.logger.info "Broadcasting status for #{source.name}: #{status_message}"
      source.update_status_and_broadcast(status_message)
      
      # Broadcast recent posts update if new posts were created
      source.broadcast_recent_posts_update if new_posts_count > 0
    rescue => e
      Rails.logger.error "Error fetching from #{source.name}: #{e.message}"
      Rails.logger.error "Full error: #{e.inspect}"
      source.update_status_and_broadcast("error: #{e.message}")
    end
  end
end