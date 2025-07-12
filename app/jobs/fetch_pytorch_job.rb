class FetchPytorchJob < ApplicationJob
  queue_as :default

  def perform(source_id = nil)
    if source_id
      source = Source.find(source_id)
      fetch_from_source(source)
    else
      Source.active.discourse.each do |source|
        fetch_from_source(source) if source.url.include?('pytorch.org')
      end
    end
  end

  private

  def fetch_from_source(source)
    return unless source.url.include?('pytorch.org')

    begin
      service = DiscourseService.new(source)
      topics = service.fetch_latest_topics
      
      new_posts_count = 0
      topics.each do |topic|
        if service.create_post_from_topic(topic)
          new_posts_count += 1
        end
      end
      
      source.update!(last_fetched_at: Time.current)
      status_message = new_posts_count > 0 ? "ok (#{new_posts_count} new)" : "ok"
      Rails.logger.info "Broadcasting status for #{source.name}: #{status_message}"
      source.update_status_and_broadcast(status_message)
    rescue => e
      Rails.logger.error "Error fetching from #{source.name}: #{e.message}"
      Rails.logger.error "Full error: #{e.inspect}"
      source.update_status_and_broadcast("error: #{e.message}")
    end
  end
end