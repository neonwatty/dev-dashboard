require "test_helper"

class SourceTest < ActiveSupport::TestCase
  # Validation tests
  test "should be valid with valid attributes" do
    source = sources(:huggingface_forum)
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
    source = sources(:huggingface_forum)
    source.source_type = nil
    assert_not source.valid?
    assert_includes source.errors[:source_type], "can't be blank"
  end

  test "should require url" do
    source = sources(:huggingface_forum)
    source.url = nil
    assert_not source.valid?
    assert_includes source.errors[:url], "can't be blank"
  end

  test "should require valid url format" do
    source = sources(:huggingface_forum)
    source.url = "invalid-url"
    assert_not source.valid?
    assert_includes source.errors[:url], "is invalid"
  end

  test "should accept http and https urls" do
    source = sources(:huggingface_forum)
    
    source.url = "http://example.com"
    assert source.valid?
    
    source.url = "https://example.com"
    assert source.valid?
  end

  test "should require active to be boolean" do
    source = sources(:huggingface_forum)
    source.active = nil
    assert_not source.valid?
    assert_includes source.errors[:active], "is not included in the list"
  end

  # Enum tests
  test "should have valid source_type enum values" do
    source = sources(:huggingface_forum)
    
    ['github', 'reddit', 'discourse', 'rss'].each do |type|
      source.source_type = type
      assert source.valid?, "Should accept source_type: #{type}"
    end
  end

  test "should reject invalid source_type" do
    source = sources(:huggingface_forum)
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
    source = sources(:huggingface_forum)
    assert_equal({}, source.config_hash)
  end

  test "config_hash should handle invalid JSON gracefully" do
    source = sources(:huggingface_forum)
    source.config = "invalid json"
    assert_equal({}, source.config_hash)
  end

  test "config_hash should clean up malformed config with prefix" do
    source = sources(:huggingface_forum)
    source.config = 'Config: {"keywords": ["test"], "limit": 25}'
    expected = {"keywords" => ["test"], "limit" => 25}
    assert_equal expected, source.config_hash
  end

  test "config_hash should handle config with extra whitespace and newlines" do
    source = sources(:huggingface_forum)
    source.config = "Config: {\"keywords\": [\"test\"]}\r\n\r\n"
    expected = {"keywords" => ["test"]}
    assert_equal expected, source.config_hash
  end

  test "config_hash= should set JSON config" do
    source = sources(:huggingface_forum)
    new_config = {"keywords" => ["ruby", "rails"], "max_items" => 50}
    source.config_hash = new_config
    assert_equal new_config.to_json, source.config
    assert_equal new_config, source.config_hash
  end

  # Connection status methods
  test "connection_ok? should return true for ok status" do
    source = sources(:huggingface_forum)
    source.status = 'ok'
    assert source.connection_ok?
  end

  test "connection_ok? should return false for error status" do
    source = sources(:inactive_source)
    assert_equal 'error', source.status
    assert_not source.connection_ok?
  end

  test "connection_ok? should return false for nil status" do
    source = sources(:huggingface_forum)
    source.status = nil
    assert_not source.connection_ok?
  end

  # Edge cases
  test "should handle very long names" do
    source = sources(:huggingface_forum)
    long_name = "a" * 1000
    source.name = long_name
    assert source.valid?
  end

  test "should handle complex config JSON" do
    source = sources(:huggingface_forum)
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
    source = sources(:huggingface_forum)
    source.last_fetched_at = nil
    assert source.valid?
  end

  test "should handle future last_fetched_at" do
    source = sources(:huggingface_forum)
    source.last_fetched_at = 1.hour.from_now
    assert source.valid?
  end
end
