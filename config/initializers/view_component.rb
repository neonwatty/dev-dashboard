# frozen_string_literal: true

# ViewComponent configuration
# Configure component generator to use mobile-responsive base class by default
Rails.application.config.generators do |g|
  g.view_component = true
  g.test_framework :test_unit
  g.helper false
end