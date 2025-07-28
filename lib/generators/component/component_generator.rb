# frozen_string_literal: true

# Custom component generator that creates mobile-responsive ViewComponents by default
class ComponentGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  desc "Generate a mobile-responsive ViewComponent"

  class_option :mobile_responsive, type: :boolean, default: true, 
               desc: "Generate with mobile-responsive base class"
  class_option :stimulus, type: :boolean, default: false,
               desc: "Generate with Stimulus controller"
  class_option :preview, type: :boolean, default: true,
               desc: "Generate component preview"

  def create_component_file
    template "component.rb.tt", "app/components/#{file_name}_component.rb"
  end

  def create_template_file
    template "component.html.erb.tt", "app/components/#{file_name}_component.html.erb"
  end

  def create_stimulus_controller
    return unless options[:stimulus]
    
    template "component_controller.js.tt", "app/javascript/controllers/#{file_name.gsub('_', '-')}_controller.js"
  end

  def create_preview_file
    return unless options[:preview]
    
    create_file "test/components/previews/#{file_name}_component_preview.rb", preview_content
  end

  def create_test_file
    create_file "test/components/#{file_name}_component_test.rb", test_content
  end

  private

  def component_class_name
    "#{class_name}Component"
  end

  def base_class_name
    options[:mobile_responsive] ? "MobileResponsiveComponent" : "ViewComponent::Base"
  end

  def stimulus_controller_name
    file_name.gsub('_', '-')
  end

  def preview_content
    <<~RUBY
      # frozen_string_literal: true

      class #{component_class_name}Preview < ViewComponent::Preview
        def default
          render #{component_class_name}.new
        end

        def with_mobile_viewport
          render #{component_class_name}.new
        end
      end
    RUBY
  end

  def test_content
    <<~RUBY
      # frozen_string_literal: true

      require "test_helper"

      class #{component_class_name}Test < ViewComponent::TestCase
        def test_renders_component
          render_inline #{component_class_name}.new

          assert_selector "[data-testid='#{file_name.gsub('_', '-')}-component']"
        end

        def test_mobile_responsive_classes
          render_inline #{component_class_name}.new

          # Test that mobile-responsive classes are applied
          assert_selector ".sm\\\\:"
        end

        def test_touch_targets_meet_accessibility_requirements
          render_inline #{component_class_name}.new

          # Ensure touch targets are at least 44px
          assert_selector "[class*='min-h-[44px]']"
        end
      end
    RUBY
  end
end