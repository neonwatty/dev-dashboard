require_relative '../services/github_service'

class FetchGithubIssuesJob < ApplicationJob
  queue_as :default

  def perform(source_id = nil)
    if source_id
      source = Source.find(source_id)
      fetch_from_source(source)
    else
      Source.active.auto_fetch_enabled.github.each do |source|
        fetch_from_source(source)
      end
    end
  end

  private

  def fetch_from_source(source)
    return unless source.url.include?('github.com')
    return unless source.auto_fetch_enabled?

    begin
      service = GitHubService.new(source)
      issues = service.fetch_issues
      
      new_posts_count = 0
      issues.each do |issue|
        if service.create_post_from_issue(issue)
          new_posts_count += 1
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