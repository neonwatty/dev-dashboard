source = Source.first
puts "Testing refresh for: #{source.name}"
puts "Initial status: #{source.status}"

# Simulate what the controller does
source.update_status_and_broadcast('refreshing...')
puts "Status after update: #{source.status}"

# Queue a job
case source.source_type
when 'discourse'
  if source.url.include?('huggingface.co')
    FetchHuggingFaceJob.perform_later(source.id)
    puts "Queued FetchHuggingFaceJob"
  end
when 'github'
  FetchGithubIssuesJob.perform_later(source.id)
  puts "Queued FetchGithubIssuesJob"
end

# Check if jobs are enqueued
puts "Active Job queue size: #{ActiveJob::Base.queue_adapter.enqueued_jobs.size}" rescue nil

# Wait a bit and check status
sleep 2
source.reload
puts "Final status: #{source.status}"