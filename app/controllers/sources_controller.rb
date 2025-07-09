require 'net/http'

class SourcesController < ApplicationController
  before_action :set_source, only: [:show, :edit, :update, :destroy, :refresh, :test_connection]

  def index
    @sources = Source.all.order(:name)
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
      render :new
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
    @source.destroy
    redirect_to sources_url, notice: 'Source was successfully deleted.'
  end
  
  def refresh
    case @source.source_type
    when 'discourse'
      if @source.url.include?('huggingface.co')
        FetchHuggingFaceJob.perform_later(@source.id)
      elsif @source.url.include?('pytorch.org')
        FetchPytorchJob.perform_later(@source.id)
      end
    when 'github'
      FetchGithubIssuesJob.perform_later(@source.id)
    when 'rss'
      # FetchRSSJob.perform_later(@source.id)
    when 'reddit'
      # FetchRedditJob.perform_later(@source.id)
    end
    
    redirect_to @source, notice: 'Refresh started for this source.'
  end
  
  def test_connection
    # Simple connection test
    begin
      response = Net::HTTP.get_response(URI(@source.url))
      if response.code.to_i < 400
        @source.update(status: 'ok')
        redirect_to @source, notice: 'Connection test successful!'
      else
        @source.update(status: "error: HTTP #{response.code}")
        redirect_to @source, alert: "Connection failed: HTTP #{response.code}"
      end
    rescue => e
      @source.update(status: "error: #{e.message}")
      redirect_to @source, alert: "Connection failed: #{e.message}"
    end
  end

  private

  def set_source
    @source = Source.find(params[:id])
  end

  def source_params
    params.require(:source).permit(:name, :source_type, :url, :config, :active)
  end
end
