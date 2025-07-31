module Caching
  extend ActiveSupport::Concern
  
  included do
    # Cache key generation methods available to all controllers
  end
  
  private
  
  # Generate consistent cache keys for collections
  def collection_cache_key(collection, prefix = nil, extra = {})
    key_parts = [
      prefix || controller_name,
      collection.maximum(:updated_at)&.to_i,
      collection.count,
      Current.user&.id,
      Current.user&.updated_at&.to_i,
      request.format.symbol,
      extra
    ].compact
    
    key_parts.join("/")
  end
  
  # Generate cache keys for individual records
  def record_cache_key(record, prefix = nil, extra = {})
    key_parts = [
      prefix || controller_name,
      record.id,
      record.updated_at.to_i,
      Current.user&.id,
      Current.user&.updated_at&.to_i,
      extra
    ].compact
    
    key_parts.join("/")
  end
  
  # Set appropriate cache headers based on content type and user status
  def set_cache_headers_for_content(expires_in_time = nil)
    return unless request.get?
    
    if authenticated?
      # Private content - cache but don't share
      case request.format.symbol
      when :html
        expires_in expires_in_time || 5.minutes, public: false
      when :json
        expires_in expires_in_time || 2.minutes, public: false
      when :turbo_stream
        expires_in expires_in_time || 30.seconds, public: false
      else
        expires_in expires_in_time || 1.minute, public: false
      end
    else
      # Public content - can be cached by proxies
      expires_in expires_in_time || 10.minutes, public: true
    end
  end
  
  # Clear related caches when content changes
  def clear_related_caches(*patterns)
    patterns.each do |pattern|
      Rails.cache.delete_matched("#{pattern}/*")
    end
  end
  
  # Conditional GET support for collections
  def set_etag_and_last_modified_for_collection(collection, options = {})
    etag_components = [
      collection.maximum(:updated_at)&.to_i,
      collection.count,
      Current.user&.id,
      Current.user&.updated_at&.to_i,
      request.url,
      options
    ].compact
    
    last_modified = collection.maximum(:updated_at)
    
    fresh_when(
      etag: etag_components,
      last_modified: last_modified,
      public: !authenticated?
    )
  end
  
  # Conditional GET support for individual records
  def set_etag_and_last_modified_for_record(record, options = {})
    etag_components = [
      record.updated_at.to_i,
      Current.user&.id,
      Current.user&.updated_at&.to_i,
      options
    ].compact
    
    fresh_when(
      etag: etag_components,
      last_modified: record.updated_at,
      public: !authenticated?
    )
  end
  
  # Cache expensive operations
  def cache_expensive_operation(key, expires_in: 1.hour, &block)
    Rails.cache.fetch(key, expires_in: expires_in, &block)
  end
end