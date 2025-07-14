require 'net/http'
require_relative '../services/github_trending_service'
require_relative '../services/github_trending_scraper_service'

class SourcesController < ApplicationController
  before_action :set_source, only: [:show, :edit, :update, :destroy, :refresh, :test_connection]

  def index
    @sources = Source.all.order(:name)
  end
  
  def refresh_all
    active_sources = Source.active.auto_fetch_enabled
    job_count = 0
    
    active_sources.each do |source|
      source.update_status_and_broadcast('refreshing...')
      
      case source.source_type
      when 'discourse'
        if source.url.include?('huggingface.co')
          FetchHuggingFaceJob.perform_later(source.id)
          job_count += 1
        elsif source.url.include?('pytorch.org')
          FetchPytorchJob.perform_later(source.id)
          job_count += 1
        end
      when 'github'
        FetchGithubIssuesJob.perform_later(source.id)
        job_count += 1
      when 'rss'
        if source.url.include?('news.ycombinator.com') || source.name.downcase.include?('hacker news')
          FetchHackerNewsJob.perform_later(source.id)
          job_count += 1
        else
          FetchRssJob.perform_later(source.id)
          job_count += 1
        end
      when 'reddit'
        FetchRedditJob.perform_later(source.id)
        job_count += 1
      when 'github_trending'
        FetchGithubTrendingJob.perform_later(source.id)
        job_count += 1
      end
    end
    
    redirect_to sources_path, notice: "Queued #{job_count} refresh jobs for active sources."
  end

  def show
  end

  def new
    @source = Source.new
  end

  def create
    @source = Source.new(source_params)
    @source.active = true
    
    if @source.save
      redirect_to @source, notice: 'Source was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @source.update(source_params)
      redirect_to @source, notice: 'Source was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    # Check if there are any posts from this source
    posts_count = Post.where(source: source_string_for(@source)).count
    
    if posts_count > 0
      redirect_to sources_url, alert: "Cannot delete source with #{posts_count} associated posts."
    else
      @source.destroy
      redirect_to sources_url, notice: 'Source was successfully deleted.'
    end
  end
  
  def refresh
    # Update status to indicate refresh is in progress
    @source.update_status_and_broadcast('refreshing...')
    
    # Queue the appropriate job
    job_queued = case @source.source_type
    when 'discourse'
      if @source.url.include?('huggingface.co')
        FetchHuggingFaceJob.perform_later(@source.id)
        'HuggingFace'
      elsif @source.url.include?('pytorch.org')
        FetchPytorchJob.perform_later(@source.id)
        'PyTorch'
      else
        false
      end
    when 'github'
      FetchGithubIssuesJob.perform_later(@source.id)
      'GitHub'
    when 'rss'
      if @source.url.include?('news.ycombinator.com') || @source.name.downcase.include?('hacker news')
        FetchHackerNewsJob.perform_later(@source.id)
        'Hacker News'
      else
        FetchRssJob.perform_later(@source.id)
        'RSS'
      end
    when 'reddit'
      FetchRedditJob.perform_later(@source.id)
      'Reddit'
    when 'github_trending'
      FetchGithubTrendingJob.perform_later(@source.id)
      'GitHub Trending'
    else
      false
    end
    
    respond_to do |format|
      if job_queued
        format.html { redirect_back(fallback_location: sources_path, notice: "#{job_queued} refresh job queued for #{@source.name}. Check back in a moment.") }
        format.turbo_stream do
          flash.now[:notice] = "#{job_queued} refresh job queued for #{@source.name}"
          render turbo_stream: [
            turbo_stream.replace("source_#{@source.id}_status", partial: "sources/status_badge", locals: { source: @source }),
            turbo_stream.prepend("notifications", partial: "shared/flash_notification", locals: { type: :notice, message: flash[:notice] })
          ]
        end
      else
        @source.update_status_and_broadcast('error: unsupported source type')
        format.html { redirect_back(fallback_location: sources_path, alert: "Refresh not supported for this source type yet.") }
        format.turbo_stream do
          flash.now[:alert] = "Refresh not supported for this source type yet"
          render turbo_stream: turbo_stream.prepend("notifications", partial: "shared/flash_notification", locals: { type: :alert, message: flash[:alert] })
        end
      end
    end
  end
  
  def test_connection
    # Handle GitHub Trending sources differently since they don't have URLs
    if @source.source_type == 'github_trending'
      test_github_trending_connection
    else
      test_url_based_connection
    end
  end

  private

  def test_github_trending_connection
    begin
      # Use appropriate service based on config
      config = @source.config_hash
      if config['use_scraper'] == true
        service = GitHubTrendingScraperService.new(@source)
        method_name = "scraper"
      else
        service = GitHubTrendingService.new(@source)
        method_name = "API"
      end
      
      # Test with a minimal call to verify connectivity
      repositories = service.fetch_trending_repositories(since: 'daily')
      
      @source.update_status_and_broadcast('ok')
      redirect_to @source, notice: "GitHub Trending #{method_name} connection successful! Found #{repositories.length} trending repositories."
    rescue => e
      error_message = case e.message
      when /rate limit/i
        "Rate limit exceeded. Please check your GitHub token or try again later."
      when /401|403/
        "Authentication failed. Please check your GitHub token."
      when /422/
        "Invalid search parameters. Please check your configuration."
      else
        e.message
      end
      
      @source.update_status_and_broadcast("error: #{error_message}")
      redirect_to @source, alert: "GitHub Trending connection failed: #{error_message}"
    end
  end

  def test_url_based_connection
    # Simple connection test for URL-based sources
    begin
      response = Net::HTTP.get_response(URI(@source.url))
      if response.code.to_i < 400
        @source.update_status_and_broadcast('ok')
        redirect_to @source, notice: 'Connection test successful!'
      else
        @source.update_status_and_broadcast("error: HTTP #{response.code}")
        redirect_to @source, alert: "Connection failed: HTTP #{response.code}"
      end
    rescue => e
      @source.update_status_and_broadcast("error: #{e.message}")
      redirect_to @source, alert: "Connection failed: #{e.message}"
    end
  end

  def set_source
    @source = Source.find(params[:id])
  end

  def source_params
    params.require(:source).permit(:name, :source_type, :url, :config, :active, :auto_fetch_enabled)
  end
  
  def source_string_for(source)
    case source.source_type
    when 'discourse'
      if source.url.include?('huggingface.co')
        'huggingface'
      elsif source.url.include?('pytorch.org')
        'pytorch'
      else
        'discourse'
      end
    when 'github'
      'github'
    when 'reddit'
      'reddit'
    when 'rss'
      if source.url.include?('news.ycombinator.com') || source.name.downcase.include?('hacker news')
        'hackernews'
      else
        'rss'
      end
    else
      source.source_type
    end
  end
end
