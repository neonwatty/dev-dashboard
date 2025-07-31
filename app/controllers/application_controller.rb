class ApplicationController < ActionController::Base
  include Authentication
  include Caching
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  protected
  
  # Set ETags for API responses with conditional GET support
  def set_etag_for_collection(collection, options = {})
    etag = [
      collection.maximum(:updated_at)&.to_i,
      collection.count,
      Current.user&.id,
      request.url,
      options
    ].compact
    
    fresh_when(etag: etag, last_modified: collection.maximum(:updated_at), public: false)
  end
  
  def set_etag_for_record(record, options = {})
    etag = [
      record.updated_at.to_i,
      Current.user&.id,
      options
    ].compact
    
    fresh_when(etag: etag, last_modified: record.updated_at, public: false)
  end
  
  # Cache key helpers for consistent caching
  def posts_cache_key(posts_relation = nil, extra = {})
    relation = posts_relation || Post.all
    [
      "posts",
      relation.maximum(:updated_at)&.to_i,
      relation.count,
      Current.user&.id,
      Current.user&.updated_at&.to_i,
      extra
    ].compact.join("/")
  end
  
  def user_cache_key(extra = {})
    [
      "user",
      Current.user&.id,
      Current.user&.updated_at&.to_i,
      extra
    ].compact.join("/")
  end
  
  # Set cache headers for static assets
  def set_static_cache_headers
    expires_in 1.year, public: true if request.format.symbol.in?([:css, :js, :png, :jpg, :jpeg, :gif, :webp, :svg])
  end
end
