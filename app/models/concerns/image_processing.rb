# frozen_string_literal: true

# Image Processing concern for generating LQIP (Low Quality Image Placeholders)
# and responsive image variants with WebP support
module ImageProcessing
  extend ActiveSupport::Concern

  included do
    # Enable image processing for attachments if using Active Storage
    # Note: This concern is designed to work with both Active Storage and external images
  end

  module ClassMethods
    # Generate LQIP data URI from image file or URL
    # @param image_source [String, IO] Image file path, URL, or file object
    # @param quality [Integer] JPEG quality for LQIP (default: 20)
    # @param width [Integer] LQIP width in pixels (default: 32)
    # @return [String] Data URI for the LQIP
    def generate_lqip(image_source, quality: 20, width: 32)
      require 'image_processing/mini_magick'
      
      begin
        # Create a low-quality, small version of the image
        processed_image = ::ImageProcessing::MiniMagick
          .source(image_source)
          .resize_to_limit(width, nil)
          .convert('jpeg')
          .saver(quality: quality)
          .call

        # Read the processed image data
        image_data = File.binread(processed_image.path)
        
        # Clean up temporary file
        File.unlink(processed_image.path) if File.exist?(processed_image.path)
        
        # Generate data URI
        base64_data = Base64.strict_encode64(image_data)
        "data:image/jpeg;base64,#{base64_data}"
      rescue => e
        Rails.logger.warn "Failed to generate LQIP: #{e.message}"
        generate_fallback_lqip(width)
      end
    end

    # Generate WebP version of an image with JPEG fallback
    # @param image_source [String, IO] Image file path, URL, or file object
    # @param sizes [Array<Integer>] Array of widths to generate (default: responsive sizes)
    # @return [Hash] Hash with WebP and JPEG URLs for each size
    def generate_responsive_variants(image_source, sizes: [320, 480, 768, 1024, 1200, 1920])
      require 'image_processing/mini_magick'
      
      variants = {}
      
      sizes.each do |width|
        begin
          # Generate WebP version
          webp_image = ::ImageProcessing::MiniMagick
            .source(image_source)
            .resize_to_limit(width, nil)
            .convert('webp')
            .saver(quality: 85, method: 6) # High quality WebP with good compression
            .call

          # Generate JPEG fallback
          jpeg_image = ::ImageProcessing::MiniMagick
            .source(image_source)
            .resize_to_limit(width, nil)
            .convert('jpeg')
            .saver(quality: 85, strip: true, interlace: 'Plane') # Progressive JPEG
            .call

          variants[width] = {
            webp: webp_image.path,
            jpeg: jpeg_image.path,
            width: width
          }
        rescue => e
          Rails.logger.warn "Failed to generate variant for width #{width}: #{e.message}"
        end
      end
      
      variants
    end

    # Generate fallback LQIP as a solid color or gradient
    # @param width [Integer] Width of the placeholder
    # @param color [String] Hex color for solid placeholder (default: light gray)
    # @return [String] Data URI for fallback LQIP
    def generate_fallback_lqip(width = 32, color = '#f3f4f6')
      height = (width * 0.6).round # 3:2 aspect ratio
      
      # Create a simple SVG placeholder
      svg = <<~SVG
        <svg width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">
          <rect width="100%" height="100%" fill="#{color}"/>
          <circle cx="50%" cy="50%" r="#{width/8}" fill="#d1d5db" opacity="0.5"/>
        </svg>
      SVG
      
      "data:image/svg+xml;base64,#{Base64.strict_encode64(svg.strip)}"
    end

    # Extract dominant color from image for background
    # @param image_source [String, IO] Image file path, URL, or file object
    # @return [String] Hex color code
    def extract_dominant_color(image_source)
      require 'image_processing/mini_magick'
      
      begin
        # Resize to 1x1 pixel to get average color
        color_sample = ::ImageProcessing::MiniMagick
          .source(image_source)
          .resize_to_fill(1, 1)
          .convert('txt')
          .call

        # Parse the color from ImageMagick's txt format
        color_info = File.read(color_sample.path)
        if match = color_info.match(/srgba?\((\d+),(\d+),(\d+)/)
          r, g, b = match[1].to_i, match[2].to_i, match[3].to_i
          "#%02x%02x%02x" % [r, g, b]
        else
          '#f3f4f6' # Default gray
        end
      rescue => e
        Rails.logger.warn "Failed to extract dominant color: #{e.message}"
        '#f3f4f6' # Default gray
      end
    ensure
      # Clean up temporary file
      File.unlink(color_sample.path) if color_sample&.path && File.exist?(color_sample.path)
    end
  end

  # Instance methods for models that include this concern
  
  # Generate LQIP for an attached image (Active Storage)
  def generate_attachment_lqip(attachment_name, **options)
    attachment = public_send(attachment_name)
    return nil unless attachment.attached?
    
    self.class.generate_lqip(attachment.blob.open, **options)
  end

  # Generate responsive variants for an attached image
  def generate_attachment_variants(attachment_name, **options)
    attachment = public_send(attachment_name)
    return {} unless attachment.attached?
    
    self.class.generate_responsive_variants(attachment.blob.open, **options)
  end

  # Cache key for image processing results
  def image_cache_key(attachment_name, variant_type = 'lqip')
    attachment = public_send(attachment_name)
    return nil unless attachment.attached?
    
    "image_processing/#{attachment.blob.key}/#{variant_type}/#{attachment.blob.checksum}"
  end
end