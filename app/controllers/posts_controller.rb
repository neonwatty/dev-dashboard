class PostsController < ApplicationController
  allow_unauthenticated_access only: [:index, :show]
  before_action :set_post, only: [:show, :mark_as_read, :mark_as_ignored, :mark_as_responded]
  
  def index
    # Show landing page for non-authenticated users
    unless authenticated?
      render 'landing' and return
    end
    
    @posts = Post.all
    
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
    
    @posts = @posts.page(params[:page]).per(20)
    
    # For filter options
    @sources = Source.active.pluck(:name).compact
    @all_tags = extract_all_tags
    @subreddits = extract_all_subreddits
    
    # Handle Turbo Frame requests for filtering
    respond_to do |format|
      format.html # Regular page load
      format.turbo_stream do
        # For Turbo Frame requests, render both posts and pagination
        render turbo_stream: [
          turbo_stream.replace("posts-list", partial: "posts/posts_list", locals: { posts: @posts }),
          turbo_stream.replace("posts-pagination", partial: "posts/pagination", locals: { posts: @posts })
        ]
      end
    end
  end

  def show
  end
  
  def mark_as_read
    @post.update!(status: 'read')
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: posts_path) }
      format.json { head :ok }
    end
  end
  
  def mark_as_ignored
    @post.update!(status: 'ignored')
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back(fallback_location: posts_path) }
      format.json { head :ok }
    end
  end
  
  def mark_as_responded
    @post.update!(status: 'responded')
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
  
  def extract_all_tags
    tags = []
    Post.where.not(tags: [nil, '']).find_each do |post|
      tags.concat(post.tags_array)
    end
    tags.uniq.sort
  end
  
  def extract_all_subreddits
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
