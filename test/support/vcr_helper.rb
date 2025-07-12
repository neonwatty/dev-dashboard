# Helper methods for VCR tests
module VcrHelper
  # Use VCR with common options for Discourse tests
  def with_discourse_cassette(name, options = {})
    default_options = {
      record: :new_episodes,
      re_record_interval: 7.days,
      match_requests_on: [:method, :uri, :query]
    }
    
    VCR.use_cassette("discourse/#{name}", default_options.merge(options)) do
      yield
    end
  end
  
  # Use VCR for integration tests
  def with_integration_cassette(name, options = {})
    default_options = {
      record: :new_episodes,
      re_record_interval: 1.day,
      match_requests_on: [:method, :uri]
    }
    
    VCR.use_cassette("integration/#{name}", default_options.merge(options)) do
      yield
    end
  end
  
  # Check if we're recording a new cassette
  def recording_cassette?
    VCR.current_cassette&.recording?
  end
  
  # Helper to respect rate limits when recording
  def respectful_pause(seconds = 0.5)
    sleep seconds if recording_cassette?
  end
  
  # Assert that a cassette was used (not just created)
  def assert_cassette_used
    cassette = VCR.current_cassette
    assert_not_nil cassette, "Should be using a VCR cassette"
    
    if cassette.recording?
      puts "\n📼 Recording new cassette: #{cassette.name}"
    else
      puts "\n▶️  Playing back cassette: #{cassette.name}"
      assert cassette.http_interactions.any?, "Cassette should have recorded interactions"
    end
  end
  
  # Clean up posts for specific sources
  def clean_discourse_posts
    Post.where(source: ['huggingface', 'pytorch', 'discourse']).delete_all
  end
  
  # Wait for async job with timeout
  def wait_for_job_completion(source, timeout: 5)
    start_time = Time.current
    
    loop do
      source.reload
      break if source.status != 'refreshing...'
      
      if Time.current - start_time > timeout
        flunk "Job did not complete within #{timeout} seconds"
      end
      
      sleep 0.1
    end
  end
end

# Include in test classes
ActiveSupport::TestCase.include VcrHelper if defined?(VcrHelper)