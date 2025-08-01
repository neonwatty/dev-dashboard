require "test_helper"

class SourceTest < ActiveSupport::TestCase
  # Validation tests
  test "should be valid with valid attributes" do
    source = sources(:one)
    assert source.valid?
  end

  test "should require name" do
    source = Source.new(
      source_type: 'github',
      url: 'https://github.com/test/repo',
      active: true
    )
    assert_not source.valid?
    assert_includes source.errors[:name], "can't be blank"
  end

  test "should require source_type" do
    source = sources(:one)
    source.source_type = nil
    assert_not source.valid?
    assert_includes source.errors[:source_type], "can't be blank"
  end

  test "should require url" do
    source = sources(:one)
    source.url = nil
    assert_not source.valid?
    assert_includes source.errors[:url], "can't be blank"
  end

  test "should require valid url format" do
    source = sources(:one)
    source.url = "invalid-url"
    assert_not source.valid?
    assert_includes source.errors[:url], "is invalid"
  end

  test "should accept http and https urls" do
    source = sources(:one)
    
    source.url = "http://unique-example-test.com"
    assert source.valid?
    
    source.url = "https://unique-example-test.com"
    assert source.valid?
  end

  test "should require active to be boolean" do
    source = sources(:one)
    source.active = nil
    assert_not source.valid?
    assert_includes source.errors[:active], "is not included in the list"
  end

  # Enum tests
  test "should have valid source_type enum values" do
    source = sources(:one)
    
    ['github', 'reddit', 'discourse', 'rss', 'github_trending'].each do |type|
      source.source_type = type
      assert source.valid?, "Should accept source_type: #{type}"
    end
  end

  test "should reject invalid source_type" do
    source = sources(:one)
    assert_raises(ArgumentError) do
      source.source_type = 'invalid_type'
    end
  end

  # Scope tests
  test "active scope should only return active sources" do
    active_sources = Source.active
    active_sources.each do |source|
      assert source.active?, "All sources should be active"
    end
    
    # Should not include inactive source
    assert_not_includes active_sources, sources(:inactive_source)
  end

  test "by_type scope should filter by source_type" do
    github_sources = Source.by_type('github')
    github_sources.each do |source|
      assert_equal 'github', source.source_type
    end
  end

  # Config hash methods
  test "config_hash should parse JSON config" do
    source = sources(:rails_github)
    expected_config = {"labels" => ["bug", "enhancement"]}
    assert_equal expected_config, source.config_hash
  end

  test "config_hash should return empty hash for blank config" do
    source = sources(:one)
    assert_equal({}, source.config_hash)
  end

  test "config_hash should handle invalid JSON gracefully" do
    source = sources(:one)
    source.config = "invalid json"
    assert_equal({}, source.config_hash)
  end

  test "config_hash should clean up malformed config with prefix" do
    source = sources(:one)
    source.config = 'Config: {"keywords": ["test"], "limit": 25}'
    expected = {"keywords" => ["test"], "limit" => 25}
    assert_equal expected, source.config_hash
  end

  test "config_hash should handle config with extra whitespace and newlines" do
    source = sources(:one)
    source.config = "Config: {\"keywords\": [\"test\"]}\r\n\r\n"
    expected = {"keywords" => ["test"]}
    assert_equal expected, source.config_hash
  end

  test "config_hash= should set JSON config" do
    source = sources(:one)
    new_config = {"keywords" => ["ruby", "rails"], "max_items" => 50}
    source.config_hash = new_config
    assert_equal new_config.to_json, source.config
    assert_equal new_config, source.config_hash
  end

  # Connection status methods
  test "connection_ok? should return true for ok status" do
    source = sources(:one)
    source.status = 'ok'
    assert source.connection_ok?
  end

  test "connection_ok? should return false for error status" do
    source = sources(:inactive_source)
    assert_equal 'error', source.status
    assert_not source.connection_ok?
  end

  test "connection_ok? should return false for nil status" do
    source = sources(:one)
    source.status = nil
    assert_not source.connection_ok?
  end

  # Edge cases
  test "should handle very long names" do
    source = sources(:one)
    long_name = "a" * 1000
    source.name = long_name
    assert source.valid?
  end

  test "should handle complex config JSON" do
    source = sources(:one)
    complex_config = {
      "keywords" => ["ruby", "rails"],
      "filters" => {
        "labels" => ["bug", "enhancement"],
        "min_score" => 10
      },
      "options" => {
        "max_items" => 100,
        "sort_by" => "priority"
      }
    }
    source.config_hash = complex_config
    assert source.valid?
    assert_equal complex_config, source.config_hash
  end

  test "should handle nil last_fetched_at" do
    source = sources(:one)
    source.last_fetched_at = nil
    assert source.valid?
  end

  test "should handle future last_fetched_at" do
    source = sources(:one)
    source.last_fetched_at = 1.hour.from_now
    assert source.valid?
  end

  # GitHub Trending specific tests
  test "github_trending should not require url" do
    source = Source.new(
      name: 'Test GitHub Trending',
      source_type: 'github_trending',
      active: true,
      config: '{"since": "daily"}'
    )
    assert source.valid?, "GitHub Trending should be valid without URL"
  end

  test "github_trending should be valid with url" do
    source = Source.new(
      name: 'Test GitHub Trending with URL',
      source_type: 'github_trending',
      url: 'https://example.com',
      active: true,
      config: '{"since": "daily"}'
    )
    assert source.valid?, "GitHub Trending should be valid with URL"
  end

  test "github_trending should handle various config options" do
    source = sources(:github_trending)
    
    # Test with complex config
    complex_config = {
      "since" => "weekly",
      "language" => "Python",
      "preferred_languages" => ["Python", "JavaScript", "Go"],
      "token" => "github_token_123"
    }
    source.config_hash = complex_config
    assert source.valid?
    assert_equal complex_config, source.config_hash
  end

  test "github_trending should default auto_fetch_enabled to true" do
    source = Source.create!(
      name: 'New GitHub Trending',
      source_type: 'github_trending',
      active: true
    )
    assert source.auto_fetch_enabled?, "auto_fetch_enabled should default to true"
  end
end
