# Configure Solid Queue
Rails.application.configure do
  # Use solid_queue as the Active Job adapter
  config.active_job.queue_adapter = :solid_queue
end