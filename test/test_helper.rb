ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"
require "vcr"
require "timecop"

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

# Configure VCR
VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :webmock
  config.default_cassette_options = { record: :new_episodes }
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add custom test helpers here

    # Clean up time after each test
    def teardown
      Timecop.return
      super
    end

    # Helper method to stub successful API responses
    def stub_successful_api_request(url, response_body)
      stub_request(:get, url)
        .to_return(status: 200, body: response_body, headers: { 'Content-Type' => 'application/json' })
    end

    # Helper method to stub failed API responses
    def stub_failed_api_request(url, status = 500)
      stub_request(:get, url)
        .to_return(status: status, body: '{"error": "API Error"}', headers: { 'Content-Type' => 'application/json' })
    end
  end
end

# Configure Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end
