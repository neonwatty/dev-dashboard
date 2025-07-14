module PostCreation
  extend ActiveSupport::Concern

  private

  def find_or_update_post(source_name, external_id, attributes)
    post = Post.find_or_initialize_by(
      source: source_name,
      external_id: external_id.to_s
    )

    # If it's a new post, create it
    if post.new_record?
      post.assign_attributes(attributes)
      post.status = 'unread'
      post.save!
      return { created: true, updated: false, post: post }
    end

    # For existing posts, check if we should update
    case post.status
    when 'ignored'
      # User explicitly ignored this - don't update or change status
      return { created: false, updated: false, post: post }
    when 'read', 'responded'
      # Check if there's significant new activity
      if should_update_post?(post, attributes)
        # Update the post data but preserve the status
        current_status = post.status
        post.assign_attributes(attributes.except(:status))
        post.status = current_status # Preserve user's status
        post.save!
        return { created: false, updated: true, post: post }
      end
    when 'unread'
      # Update unread posts with latest data
      post.assign_attributes(attributes.except(:status))
      post.save!
      return { created: false, updated: true, post: post }
    end

    { created: false, updated: false, post: post }
  end

  def should_update_post?(post, new_attributes)
    # Update if posted_at changed (indicates new activity)
    if new_attributes[:posted_at] && post.posted_at != new_attributes[:posted_at]
      return true
    end

    # Update if priority score increased significantly
    if new_attributes[:priority_score] && 
       post.priority_score && 
       new_attributes[:priority_score] > post.priority_score + 2
      return true
    end

    # Update if summary changed (indicates edited content)
    if new_attributes[:summary] && post.summary != new_attributes[:summary]
      return true
    end

    # Update if it's been more than 24 hours since last update
    if post.updated_at < 24.hours.ago
      return true
    end

    false
  end
end