require "test_helper"

class DiscourseComparisonTest < ActiveJob::TestCase
  setup do
    @source = sources(:huggingface_forum)
    Post.where(source: 'huggingface').delete_all
  end

  # Example of WebMock test - complete control, predictable data
  test "WebMock example: controlled test data" do
    mock_response = {
      "topic_list" => {
        "topics" => [
          {
            "id" => 99999,
            "title" => "Test Topic for Unit Testing",
            "slug" => "test-topic-for-unit-testing",
            "created_at" => "2025-07-12T10:00:00.000Z",
            "last_poster_username" => "test_user",
            "excerpt" => "This is a controlled test excerpt",
            "tags" => ["test", "unit-testing"],
            "reply_count" => 5,
            "like_count" => 10,
            "views" => 100
          }
        ]
      }
    }.to_json

    stub_request(:get, "#{@source.url}/latest.json?page=0")
      .to_return(status: 200, body: mock_response)

    assert_difference('Post.count', 1) do
      FetchHuggingFaceJob.perform_now(@source.id)
    end

    post = Post.find_by(external_id: '99999')
    assert_equal "Test Topic for Unit Testing", post.title
    assert_equal "test_user", post.author
    assert_equal ["test", "unit-testing"], post.tags_array
    
    puts "📝 WebMock: Predictable data - created post with exact title: '#{post.title}'"
  end

  # Example of VCR test - real data, realistic scenarios  
  test "VCR example: real API responses" do
    VCR.use_cassette("discourse/real_vs_mock_comparison") do
      initial_count = Post.count
      FetchHuggingFaceJob.perform_now(@source.id)
      
      posts = Post.where(source: 'huggingface').limit(3)
      
      puts "\n📼 VCR: Real data from HuggingFace:"
      posts.each do |post|
        puts "   - #{post.title[0..50]}..."
        puts "     Author: #{post.author}, Tags: #{post.tags_array.join(', ')}"
      end
      
      # Assertions based on real API structure
      posts.each do |post|
        assert post.title.present?
        assert post.author.present?
        assert post.url.include?('discuss.huggingface.co')
        assert post.posted_at.present?
      end
      
      puts "   ✅ All #{posts.count} posts have expected real-world data structure"
    end
  end

  # Example showing how VCR catches API changes
  test "VCR catches API structure changes" do
    VCR.use_cassette("discourse/api_structure_validation") do
      service = DiscourseService.new(@source)
      topics = service.fetch_latest_topics
      
      # Test expectations based on real API structure
      first_topic = topics.first
      
      # These assertions would fail if Discourse changed their API
      assert first_topic.key?('id'), "API should return 'id' field"
      assert first_topic.key?('title'), "API should return 'title' field"
      assert first_topic.key?('created_at'), "API should return 'created_at' field"
      
      # Test for fields that might be optional
      optional_fields = ['excerpt', 'tags', 'last_poster_username']
      present_fields = optional_fields.select { |field| first_topic.key?(field) }
      
      puts "\n🔍 API Structure Analysis:"
      puts "   Required fields: ✅ id, title, created_at"
      puts "   Optional fields present: #{present_fields.join(', ')}"
      puts "   Total topics returned: #{topics.count}"
    end
  end
end