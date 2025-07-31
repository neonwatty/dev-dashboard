class PostsController < ApplicationController
  allow_unauthenticated_access only: [:index, :show]
  before_action :set_post, only: [:show, :mark_as_read, :mark_as_ignored, :mark_as_responded]
  before_action :set_cache_headers, only: [:index]
  
  def index
    # Show landing page for non-authenticated users
    unless authenticated?
      render 'landing' and return
    end
    
    @posts = Post.includes(:source_record).all
    
    # Filter out expired posts for the current user (unless showing expired)
    if Current.user && params[:show_expired] != 'true'
      @posts = @posts.not_expired_for_user(Current.user)
    end
    
    # Hide ignored posts by default unless explicitly filtering for them
    unless params[:status] == 'ignored' || params[:show_all] == 'true'
      @posts = @posts.where.not(status: 'ignored')
    end
    
    # Apply filters
    # Handle both single source (legacy) and multiple sources
    if params[:sources].present?
      # Ensure sources is always an array
      sources = params[:sources].is_a?(Array) ? params[:sources] : [params[:sources]]
      @posts = @posts.where(source: sources)
    elsif params[:source].present?
      @posts = @posts.where(source: params[:source])
    end
    
    @posts = apply_search(@posts, params[:keyword]) if params[:keyword].present?
    @posts = @posts.where(status: params[:status]) if params[:status].present?
    
    # Handle tag filtering
    if params[:tag].present?
      @posts = @posts.where("tags LIKE ?", "%#{params[:tag]}%")
    end
    
    # Handle subreddit filtering
    if params[:subreddit].present?
      @posts = @posts.where("tags LIKE ?", "%subreddit:#{params[:subreddit]}%")
    end
    
    # Handle advanced filters
    if params[:min_priority].present?
      @posts = @posts.where("priority_score >= ?", params[:min_priority].to_f)
    end
    
    if params[:after_date].present?
      @posts = @posts.where("posted_at >= ?", Date.parse(params[:after_date]))
    end
    
    # Handle posted_after parameter for "Today" filter
    if params[:posted_after].present?
      @posts = @posts.where("posted_at >= ?", params[:posted_after])
    end
    
    # Apply sorting
    case params[:sort]
    when 'priority'
      @posts = @posts.by_priority
    when 'recent'
      @posts = @posts.recent
    else
      # Default to most recent first
      @posts = @posts.recent
    end
    
    # Store total count before pagination for virtual scrolling
    @total_count = @posts.count
    
    # Use virtual scrolling for large datasets, pagination for smaller ones
    if @total_count >= 50 && params[:virtual_scroll] != 'false'
      # For virtual scrolling, load more posts but still paginate server-side for memory efficiency
      @posts = @posts.page(params[:page] || 1).per(100) # Load 100 at a time for virtual scroll
      @use_virtual_scroll = true
    else
      # Traditional pagination for smaller datasets
      @posts = @posts.page(params[:page]).per(20)
      @use_virtual_scroll = false
    end
    
    # For filter options
    @sources = Source.active.pluck(:name).compact
    @all_tags = extract_all_tags
    @subreddits = extract_all_subreddits
    
    # Handle Turbo Frame requests for filtering
    respond_to do |format|
      format.html do
        # Set ETags for HTML responses
        set_etag_for_collection(@posts, {
          filters: {
            sources: params[:sources],
            source: params[:source],
            keyword: params[:keyword],
            status: params[:status],
            tag: params[:tag],
            subreddit: params[:subreddit],
            sort: params[:sort],
            page: params[:page]
          }
        })
      end
      format.turbo_stream do
        # For Turbo Frame requests, render both posts and pagination
        render turbo_stream: [
          turbo_stream.replace("posts-list", partial: "posts/posts_list", locals: { posts: @posts }),
          turbo_stream.replace("posts-pagination", partial: "posts/pagination", locals: { posts: @posts })
        ]
      end
      format.json do
        # Set ETags for JSON API responses
        set_etag_for_collection(@posts, {
          format: :json,
          page: params[:page],
          virtual_scroll: params[:virtual_scroll]
        })
        
        # For virtual scroll infinite loading
        render json: {
          posts: @posts.map { |post| 
            {
              id: post.id,
              html: render_to_string(partial: 'posts/post_card', locals: { post: post }, formats: [:html])
            }
          },
          has_more: @posts.respond_to?(:last_page?) ? !@posts.last_page? : false,
          total_count: @total_count,
          current_page: @posts.respond_to?(:current_page) ? @posts.current_page : 1
        }
      end
    end
  end

  def show
    # Set ETags for individual post views
    set_etag_for_record(@post)
  end
  
  def mark_as_read
    @post.update!(status: 'read')
    # Clear cache after status update
    clear_posts_cache
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: posts_path) }
      format.json { head :ok }
    end
  end
  
  def mark_as_ignored
    @post.update!(status: 'ignored')
    # Clear cache after status update
    clear_posts_cache
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: posts_path) }
      format.json { head :ok }
    end
  end
  
  def mark_as_responded
    @post.update!(status: 'responded')
    # Clear cache after status update
    clear_posts_cache
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: posts_path) }
      format.json { head :ok }
    end
  end
  
  private
  
  def set_post
    @post = Post.find(params[:id])
  end
  
  def set_cache_headers
    # Set cache headers for different response types
    case request.format.symbol
    when :html
      expires_in 5.minutes, public: false if authenticated?
    when :json
      expires_in 2.minutes, public: false if authenticated?
    when :turbo_stream
      expires_in 30.seconds, public: false if authenticated?
    end
  end
  
  def clear_posts_cache
    # Clear relevant caches when posts are updated
    Rails.cache.delete_matched("posts/*")
    Rails.cache.delete_matched("tags/*")
    Rails.cache.delete_matched("sources/*")
  end
  
  def extract_all_tags
    Rails.cache.fetch("tags/all/#{Post.maximum(:updated_at)&.to_i}", expires_in: 1.hour) do
      tags = []
      Post.where.not(tags: [nil, '']).find_each do |post|
        tags.concat(post.tags_array)
      end
      tags.uniq.sort
    end
  end
  
  def extract_all_subreddits
    Rails.cache.fetch("subreddits/all/#{Post.maximum(:updated_at)&.to_i}", expires_in: 1.hour) do
      subreddits = []
      Post.where.not(tags: [nil, '']).find_each do |post|
        post.tags_array.each do |tag|
          if tag.start_with?('subreddit:')
            subreddits << tag.sub('subreddit:', '')
          end
        end
      end
      subreddits.uniq.sort
    end
  end
  
  def apply_search(posts, keyword)
    return posts if keyword.blank?
    
    # Clean and prepare search term
    search_term = "%#{keyword.strip}%"
    
    # Search across title, summary, author, and tags (SQLite compatible)
    posts.where(
      "title LIKE ? OR summary LIKE ? OR author LIKE ? OR tags LIKE ?",
      search_term, search_term, search_term, search_term
    )
  end
end
