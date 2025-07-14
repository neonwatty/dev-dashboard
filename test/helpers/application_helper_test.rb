require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  # Tests for status_color method
  test "status_color returns correct color for unread status" do
    assert_equal 'blue', status_color('unread')
  end

  test "status_color returns correct color for read status" do
    assert_equal 'green', status_color('read')
  end

  test "status_color returns correct color for ignored status" do
    assert_equal 'gray', status_color('ignored')
  end

  test "status_color returns correct color for responded status" do
    assert_equal 'purple', status_color('responded')
  end

  test "status_color returns gray for unknown status" do
    assert_equal 'gray', status_color('unknown')
    assert_equal 'gray', status_color('')
    assert_equal 'gray', status_color(nil)
  end

  # Tests for source_type_color method
  test "source_type_color returns correct color for discourse" do
    assert_equal 'blue', source_type_color('discourse')
  end

  test "source_type_color returns correct color for github" do
    assert_equal 'gray', source_type_color('github')
  end

  test "source_type_color returns correct color for reddit" do
    assert_equal 'orange', source_type_color('reddit')
  end

  test "source_type_color returns correct color for rss" do
    assert_equal 'green', source_type_color('rss')
  end

  test "source_type_color returns gray for unknown source type" do
    assert_equal 'gray', source_type_color('unknown')
    assert_equal 'gray', source_type_color('')
    assert_equal 'gray', source_type_color(nil)
  end

  # Tests for source_display_color method
  test "source_display_color returns correct color for huggingface" do
    assert_equal 'yellow', source_display_color('huggingface')
  end

  test "source_display_color returns correct color for pytorch" do
    assert_equal 'orange', source_display_color('pytorch')
  end

  test "source_display_color returns correct color for github source" do
    assert_equal 'gray', source_display_color('github')
  end

  test "source_display_color returns correct color for rss source" do
    assert_equal 'green', source_display_color('rss')
  end

  test "source_display_color returns correct color for hackernews" do
    assert_equal 'orange', source_display_color('hackernews')
  end

  test "source_display_color returns blue for unknown source" do
    assert_equal 'blue', source_display_color('unknown')
    assert_equal 'blue', source_display_color('custom_source')
    assert_equal 'blue', source_display_color('')
    assert_equal 'blue', source_display_color(nil)
  end

  # Edge case tests
  test "color methods handle case variations" do
    # Status color is case-sensitive (matches actual implementation)
    assert_equal 'gray', status_color('UNREAD')
    assert_equal 'gray', status_color('Unread')
    
    # Source type color is case-sensitive
    assert_equal 'gray', source_type_color('DISCOURSE')
    assert_equal 'gray', source_type_color('GitHub')
    
    # Source display color is case-sensitive
    assert_equal 'blue', source_display_color('HuggingFace')
    assert_equal 'blue', source_display_color('PYTORCH')
  end

  test "color methods handle symbols" do
    # Test with symbols (common in Rails)
    assert_equal 'blue', status_color(:unread.to_s)
    assert_equal 'blue', source_type_color(:discourse.to_s)
    assert_equal 'yellow', source_display_color(:huggingface.to_s)
  end

  test "all color methods return valid Tailwind color names" do
    # Valid Tailwind colors used in the app
    valid_colors = ['blue', 'green', 'gray', 'purple', 'orange', 'yellow']
    
    # Test status_color
    ['unread', 'read', 'ignored', 'responded', 'unknown'].each do |status|
      assert_includes valid_colors, status_color(status)
    end
    
    # Test source_type_color
    ['discourse', 'github', 'reddit', 'rss', 'unknown'].each do |type|
      assert_includes valid_colors, source_type_color(type)
    end
    
    # Test source_display_color
    ['huggingface', 'pytorch', 'github', 'rss', 'hackernews', 'unknown'].each do |source|
      assert_includes valid_colors, source_display_color(source)
    end
  end
end