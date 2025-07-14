class AnalysisController < ApplicationController
  before_action :require_authentication
  
  def index
    # Basic statistics
    @total_posts = Post.count
    @unread_posts = Post.where(status: 'unread').count
    @responded_posts = Post.where(status: 'responded').count
    @active_sources = Source.active.count
    
    # Posts by status
    @posts_by_status = Post.group(:status).count
    
    # Posts by source
    @posts_by_source = Post.group(:source).count.sort_by { |_, count| -count }
    
    # Recent activity (posts in last 7 days)
    @recent_posts = Post.where('posted_at >= ?', 7.days.ago).count
    
    # Top tags
    tag_counts = Hash.new(0)
    Post.where.not(tags: [nil, '']).find_each do |post|
      post.tags_array.each do |tag|
        tag_counts[tag] += 1 unless tag.start_with?('subreddit:')
      end
    end
    @top_tags = tag_counts.sort_by { |_, count| -count }.first(10)
    
    # Posts over time (last 30 days) - grouped by date
    posts_last_30_days = Post.where('posted_at >= ?', 30.days.ago)
    @posts_over_time = posts_last_30_days.group_by { |p| p.posted_at.to_date }
                                         .transform_values(&:count)
                                         .sort.to_h
    
    # Response rate
    total_non_ignored = Post.where.not(status: 'ignored').count
    @response_rate = if total_non_ignored > 0
      ((@responded_posts.to_f / total_non_ignored) * 100).round(1)
    else
      0
    end
    
    # Average posts per day (last 30 days)
    @avg_posts_per_day = (Post.where('posted_at >= ?', 30.days.ago).count / 30.0).round(1)
  end
end