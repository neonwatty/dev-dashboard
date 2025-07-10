class PostsController < ApplicationController
  allow_unauthenticated_access only: [:index, :show]
  before_action :set_post, only: [:show, :mark_as_read, :mark_as_ignored, :mark_as_responded]
  
  def index
    @posts = Post.all
    
    # Apply filters
    @posts = @posts.where(source: params[:source]) if params[:source].present?
    @posts = @posts.where("title LIKE ?", "%#{params[:keyword]}%") if params[:keyword].present?
    @posts = @posts.where(status: params[:status]) if params[:status].present?
    
    # Handle tag filtering
    if params[:tag].present?
      @posts = @posts.where("tags::text ILIKE ?", "%#{params[:tag]}%")
    end
    
    # Handle subreddit filtering
    if params[:subreddit].present?
      @posts = @posts.where("tags::text ILIKE ?", "%subreddit:#{params[:subreddit]}%")
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
    @sources = Post.distinct.pluck(:source).compact
    @all_tags = extract_all_tags
    @subreddits = extract_all_subreddits
  end

  def show
  end
  
  def mark_as_read
    @post.update!(status: 'read')
    redirect_back(fallback_location: posts_path)
  end
  
  def mark_as_ignored
    @post.update!(status: 'ignored')
    redirect_back(fallback_location: posts_path)
  end
  
  def mark_as_responded
    @post.update!(status: 'responded')
    redirect_back(fallback_location: posts_path)
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
end
