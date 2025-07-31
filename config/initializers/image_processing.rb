# frozen_string_literal: true

# Image Processing Configuration
# Sets up image processing capabilities for progressive loading and optimization

# Configure image processing backend
if defined?(ImageProcessing)
  # Use libvips as the backend for better performance
  # Falls back to MiniMagick if libvips is not available
  begin
    require 'image_processing/vips'
    ImageProcessing.configure do |config|
      config.backend = :vips
    end
    Rails.logger.info "Image processing configured with libvips backend"
  rescue LoadError
    require 'image_processing/mini_magick'
    Rails.logger.info "Image processing configured with MiniMagick backend (consider installing libvips for better performance)"
  end
end

# Configure Active Storage variants if Active Storage is being used
if defined?(ActiveStorage)
  # Set up variant processor
  Rails.application.configure do
    # Use :mini_magick or :vips
    config.active_storage.variant_processor = :mini_magick
    
    # Precompile common image variants
    config.active_storage.precompile_assets = %w[
      active_storage/previews/image.jpg
      active_storage/previews/image.webp
    ]
  end
end

# Image processing cache configuration
Rails.application.configure do
  # Cache processed images for 1 year
  config.image_processing_cache_duration = 1.year
  
  # Maximum file size for processing (10MB)
  config.max_image_processing_size = 10.megabytes
  
  # Default responsive image sizes
  config.responsive_image_sizes = [320, 480, 768, 1024, 1200, 1920]
  
  # LQIP configuration
  config.lqip_quality = 20
  config.lqip_width = 32
  
  # WebP configuration
  config.webp_quality = 85
  config.webp_method = 6  # 0-6, higher is slower but better compression
  
  # JPEG configuration
  config.jpeg_quality = 85
  config.jpeg_progressive = true
  config.jpeg_strip_metadata = true
end

# HTTP cache headers for images
if defined?(ActionDispatch)
  # Add cache headers for image assets
  Rails.application.config.middleware.insert_before(
    ActionDispatch::Static,
    Rack::Cache,
    verbose: Rails.env.development?,
    metastore: "file:#{Rails.root}/tmp/cache/rack/meta",
    entitystore: "file:#{Rails.root}/tmp/cache/rack/body"
  ) if Rails.env.production?
end

# Content Security Policy for data URIs (LQIP)
if defined?(ActionDispatch::ContentSecurityPolicy)
  Rails.application.configure do
    config.content_security_policy do |policy|
      # Allow data: URIs for LQIP images
      policy.img_src :self, :data, :https
    end
  end
end

# Performance monitoring for image processing
class ImageProcessingInstrumentation
  def self.instrument(name, payload = {})
    ActiveSupport::Notifications.instrument("image_processing.#{name}", payload) do
      yield if block_given?
    end
  end
end

# Subscribe to image processing events for monitoring
ActiveSupport::Notifications.subscribe('image_processing.lqip_generated') do |name, start, finish, id, payload|
  duration = (finish - start) * 1000
  Rails.logger.info "LQIP generated in #{duration.round(2)}ms for #{payload[:source]}"
end

ActiveSupport::Notifications.subscribe('image_processing.variants_generated') do |name, start, finish, id, payload|
  duration = (finish - start) * 1000
  Rails.logger.info "Image variants generated in #{duration.round(2)}ms for #{payload[:source]} (#{payload[:sizes].join(', ')}px)"
end

ActiveSupport::Notifications.subscribe('image_processing.error') do |name, start, finish, id, payload|
  Rails.logger.error "Image processing error: #{payload[:error]} for #{payload[:source]}"
end