# VCR Testing Guide

This project uses VCR (Video Cassette Recorder) to record real HTTP interactions with external APIs and replay them during tests. This provides a balance between realistic testing and fast, reliable test runs.

## How VCR Works

1. **Recording**: The first time a test runs, VCR records real HTTP requests and responses
2. **Playback**: Subsequent test runs use the recorded "cassettes" instead of making real HTTP calls
3. **Benefits**: Fast tests, offline testing, real API response structures

## Directory Structure

```
test/vcr_cassettes/
├── discourse/          # Discourse forum API cassettes
│   ├── huggingface_latest.yml
│   ├── pytorch_latest.yml
│   └── ...
├── github/            # GitHub API cassettes
├── reddit/            # Reddit API cassettes  
├── rss/               # RSS feed cassettes
└── integration/       # Full workflow cassettes
```

## Using VCR in Tests

### Basic Usage

```ruby
test "should fetch real posts from API" do
  VCR.use_cassette("discourse/my_test_case") do
    # This code will make real HTTP requests the first time
    # and use recorded responses on subsequent runs
    FetchHuggingFaceJob.perform_now(@source.id)
    
    # Assertions using real data structure
    posts = Post.where(source: 'huggingface')
    assert posts.count > 0
  end
end
```

### Using Helper Methods

```ruby
test "with helper methods" do
  with_discourse_cassette("my_test") do
    # Test code here
  end
end
```

### Configuration Options

```ruby
VCR.use_cassette("cassette_name", 
  record: :new_episodes,        # Record new requests, replay existing
  re_record_interval: 7.days,   # Auto re-record after 7 days
  match_requests_on: [:method, :uri, :query]  # How to match requests
) do
  # Test code
end
```

## Record Modes

- `:new_episodes` (default) - Record new requests, replay existing ones
- `:once` - Record once, never re-record
- `:all` - Always record (ignores existing cassettes)
- `:none` - Never record, only replay

## Cassette Management

### Re-recording Cassettes

To get fresh data from APIs:

```bash
# Delete specific cassette to re-record
rm test/vcr_cassettes/discourse/huggingface_latest.yml

# Delete all cassettes to re-record everything
rm -rf test/vcr_cassettes/discourse/*

# Run tests to regenerate
bundle exec rails test test/jobs/discourse_vcr_test.rb
```

### Sensitive Data

The VCR configuration automatically filters sensitive data:

```ruby
# In test_helper.rb
config.filter_sensitive_data('<DISCOURSE_API_KEY>') { ENV['DISCOURSE_API_KEY'] }
config.filter_sensitive_data('<GITHUB_TOKEN>') { ENV['GITHUB_TOKEN'] }
```

## Example Tests

### Job Testing with VCR

```ruby
test "should fetch real posts from HuggingFace forum" do
  VCR.use_cassette("discourse/huggingface_real_data") do
    initial_count = Post.count
    FetchHuggingFaceJob.perform_now(@source.id)
    
    assert Post.count > initial_count
    
    # Test with real data structure
    post = Post.where(source: 'huggingface').first
    assert post.title.present?
    assert post.url.include?('discuss.huggingface.co')
  end
end
```

### Integration Testing with VCR

```ruby
test "complete workflow with real API" do
  VCR.use_cassette("integration/full_workflow") do
    # Refresh source
    post refresh_source_path(@source)
    
    # Visit posts page  
    get posts_path
    assert_response :success
    
    # Should show real posts
    assert_select "h3", minimum: 1
  end
end
```

## Best Practices

### 1. Organize Cassettes by Feature

```
discourse/
  huggingface_latest.yml      # Normal case
  huggingface_pagination.yml  # Pagination test
  huggingface_error.yml       # Error handling
```

### 2. Use Descriptive Names

```ruby
# Good
VCR.use_cassette("discourse/huggingface_with_tags")

# Bad  
VCR.use_cassette("test1")
```

### 3. Handle Variable Data

```ruby
# For tests with timestamps or IDs that change
VCR.use_cassette("discourse/posts_#{Date.current}") do
  # Test code
end
```

### 4. Set Appropriate Re-record Intervals

```ruby
# For data that changes frequently
VCR.use_cassette("discourse/latest", re_record_interval: 1.day)

# For stable API structure tests
VCR.use_cassette("discourse/api_structure", re_record_interval: 30.days)
```

## Running Tests

```bash
# Run all VCR tests
bundle exec rails test test/jobs/discourse_vcr_test.rb

# Run specific VCR test
bundle exec rails test test/jobs/discourse_vcr_test.rb -n "test_should_fetch_real_posts_from_HuggingFace_forum"

# Run integration VCR tests
bundle exec rails test test/integration/discourse_workflow_vcr_test.rb
```

## Troubleshooting

### Cassette Not Found Error

```
VCR::Errors::UnhandledHTTPRequestError
```

**Solution**: The cassette doesn't exist. Run the test to record it, or check the cassette name.

### Real HTTP Connections When Not Expected

**Solution**: Ensure you're inside a `VCR.use_cassette` block.

### Cassette Contains Wrong Data

**Solution**: Delete the cassette file and re-run the test to re-record.

### API Rate Limiting During Recording

**Solution**: Add delays during recording:

```ruby
test "with rate limiting respect" do
  VCR.use_cassette("api_test") do
    service.fetch_data
    sleep 1 if VCR.current_cassette.recording?  # Only sleep when recording
  end
end
```

## When to Use VCR vs WebMock

### Use VCR When:
- Testing integration with real APIs
- Validating API response structure
- Testing with realistic data variety
- End-to-end workflow testing

### Use WebMock When:
- Testing error conditions
- Testing with specific controlled data
- Unit testing business logic
- Testing edge cases that are hard to reproduce

## Integration with CI/CD

Since cassettes are in `.gitignore`, they won't be committed to the repository. In CI environments:

1. VCR tests will be skipped if cassettes don't exist
2. Or configure CI to allow HTTP connections for VCR recording:

```ruby
# In test environment config
VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = true if ENV['CI']
end
```