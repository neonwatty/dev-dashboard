require "test_helper"

class SourceAutoFetchTest < ActiveSupport::TestCase
  def setup
    @source = sources(:huggingface_forum)
  end

  test "new sources have auto_fetch_enabled true by default" do
    source = Source.new(
      name: "Test Source",
      source_type: "discourse", 
      url: "https://example.com"
    )
    
    assert source.auto_fetch_enabled?, "New sources should have auto_fetch_enabled true by default"
  end

  test "auto_fetch_enabled scope filters correctly" do
    # Create a source with auto_fetch_enabled false
    disabled_source = Source.create!(
      name: "Disabled Source",
      source_type: "discourse",
      url: "https://disabled.com",
      active: true,
      auto_fetch_enabled: false
    )
    
    enabled_sources = Source.auto_fetch_enabled
    disabled_sources = Source.where(auto_fetch_enabled: false)
    
    assert_includes enabled_sources, @source
    assert_not_includes enabled_sources, disabled_source
    assert_includes disabled_sources, disabled_source
  end

  test "active.auto_fetch_enabled scope combines correctly" do
    # Create an inactive source with auto_fetch enabled
    inactive_source = Source.create!(
      name: "Inactive Source", 
      source_type: "discourse",
      url: "https://inactive.com",
      active: false,
      auto_fetch_enabled: true
    )
    
    # Create an active source with auto_fetch disabled
    disabled_source = Source.create!(
      name: "Disabled Source",
      source_type: "discourse", 
      url: "https://disabled.com",
      active: true,
      auto_fetch_enabled: false
    )
    
    sources = Source.active.auto_fetch_enabled
    
    # Should include active sources with auto_fetch enabled
    assert_includes sources, @source
    
    # Should exclude inactive sources even with auto_fetch enabled
    assert_not_includes sources, inactive_source
    
    # Should exclude active sources with auto_fetch disabled
    assert_not_includes sources, disabled_source
  end
end