require "test_helper"

class SourceRecentPostsTest < ActionDispatch::IntegrationTest
  include ApplicationHelper
  
  setup do
    @source = sources(:huggingface_forum)
    @user = users(:one)
    sign_in_as(@user)
  end

  test "source show page displays recent posts correctly" do
    # Create test posts for this source
    Post.create!(
      source: 'huggingface',
      external_id: 'test1',
      title: 'Test Post 1',
      url: 'https://discuss.huggingface.co/t/test1/1',
      author: 'test_user',
      posted_at: 1.hour.ago,
      status: 'unread',
      priority_score: 5.0
    )
    
    Post.create!(
      source: 'huggingface', 
      external_id: 'test2',
      title: 'Test Post 2',
      url: 'https://discuss.huggingface.co/t/test2/2',
      author: 'another_user',
      posted_at: 2.hours.ago,
      status: 'unread',
      priority_score: 3.0
    )
    
    # Visit source show page
    get source_url(@source)
    assert_response :success
    
    # Check that recent posts section is present
    assert_select 'h2', text: 'Recent Posts from This Source'
    
    # Check that test posts are displayed
    assert_select 'h3 a[href*="test1"]', text: 'Test Post 1'
    assert_select 'h3 a[href*="test2"]', text: 'Test Post 2'
    
    # Check that author and time info is displayed
    assert_select 'p', text: /by test_user.*ago/
    assert_select 'p', text: /by another_user.*ago/
  end
  
  test "source show page displays no posts message when no posts exist" do
    # Ensure no posts exist for this source
    Post.where(source: 'huggingface').destroy_all
    
    get source_url(@source)
    assert_response :success
    
    # Check that no posts message is displayed
    assert_select 'p', text: 'No posts have been fetched from this source yet.'
  end
  
  test "helper method source_identifier_for returns correct values" do
    # Test HuggingFace
    hf_source = sources(:huggingface_forum)
    assert_equal 'huggingface', source_identifier_for(hf_source)
    
    # Test PyTorch
    pytorch_source = sources(:pytorch_forum)
    assert_equal 'pytorch', source_identifier_for(pytorch_source)
    
    # Test GitHub
    github_source = sources(:rails_github)
    assert_equal 'github', source_identifier_for(github_source)
    
    # Test RSS (Hacker News)
    hn_source = sources(:hacker_news)
    assert_equal 'hackernews', source_identifier_for(hn_source)
  end
end