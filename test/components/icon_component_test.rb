require "test_helper"

class IconComponentTest < ViewComponent::TestCase
  def test_renders_basic_icon
    component = IconComponent.new(name: :check)
    
    render_inline(component)
    
    assert_selector "svg[fill='none']"
    assert_selector "svg[stroke='currentColor']"
    assert_selector "svg[stroke-width='2']"
    assert_selector "svg path"
  end

  def test_renders_with_size
    component = IconComponent.new(name: :check, size: :lg)
    
    render_inline(component)
    
    assert_selector "svg.w-6.h-6"
  end

  def test_renders_with_custom_css_class
    component = IconComponent.new(name: :check, css_class: "text-red-500")
    
    render_inline(component)
    
    assert_selector "svg.text-red-500"
  end

  def test_renders_with_custom_attributes
    component = IconComponent.new(name: :check, id: "test-icon", role: "img")
    
    render_inline(component)
    
    assert_selector "svg[id='test-icon']"
    assert_selector "svg[role='img']"
  end

  def test_renders_filled_icon
    component = IconComponent.new(name: :check, fill: "currentColor", stroke: "none")
    
    render_inline(component)
    
    assert_selector "svg[fill='currentColor']"
    assert_selector "svg[stroke='none']"
  end

  def test_all_sizes_are_valid
    IconComponent::SIZE_CLASSES.each_key do |size|
      component = IconComponent.new(name: :check, size: size)
      
      assert_nothing_raised do
        render_inline(component)
      end
    end
  end

  def test_raises_error_for_invalid_icon
    assert_raises ArgumentError do
      IconComponent.new(name: :nonexistent_icon)
    end
  end

  def test_raises_error_for_invalid_size
    assert_raises ArgumentError do
      IconComponent.new(name: :check, size: :invalid_size)
    end
  end

  def test_has_aria_hidden_by_default
    component = IconComponent.new(name: :check)
    
    render_inline(component)
    
    assert_selector "svg[aria-hidden='true']"
  end

  def test_renders_common_navigation_icons
    navigation_icons = [:dashboard, :sources, :analytics, :settings]
    
    navigation_icons.each do |icon|
      component = IconComponent.new(name: icon)
      
      assert_nothing_raised do
        render_inline(component)
      end
      
      assert_selector "svg path"
    end
  end

  def test_renders_common_action_icons
    action_icons = [:check, :x, :edit, :trash, :refresh]
    
    action_icons.each do |icon|
      component = IconComponent.new(name: icon)
      
      assert_nothing_raised do
        render_inline(component)
      end
      
      assert_selector "svg path"
    end
  end
end