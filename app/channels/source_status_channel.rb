class SourceStatusChannel < ApplicationCable::Channel
  def subscribed
    # Stream for all sources updates (for index page)
    stream_from "source_status:all"
    
    # Stream for specific source if source_id is provided (for show page)
    if params[:source_id].present?
      stream_from "source_status:#{params[:source_id]}"
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end