class CleanupOldPostsJob < ApplicationJob
  queue_as :low

  def perform
    # Find the most generous retention setting among all users
    # This ensures we don't delete posts that some users might still want to see
    max_retention_days = UserSetting.maximum(:post_retention_days) || 30
    
    # Calculate the cutoff date
    cutoff_date = max_retention_days.days.ago
    
    # Delete posts older than the cutoff date
    # Using posted_at as the primary timestamp since it represents when the post was originally created
    old_posts = Post.where("posted_at < ?", cutoff_date)
    
    Rails.logger.info "CleanupOldPostsJob: Deleting #{old_posts.count} posts older than #{max_retention_days} days"
    
    # Delete in batches to avoid locking the database for too long
    deleted_count = 0
    old_posts.find_in_batches(batch_size: 100) do |batch|
      batch.each(&:destroy)
      deleted_count += batch.size
    end
    
    Rails.logger.info "CleanupOldPostsJob: Successfully deleted #{deleted_count} old posts"
  end
end
