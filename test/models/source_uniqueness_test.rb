require "test_helper"

class SourceUniquenessTest < ActiveSupport::TestCase
  def setup
    @user = users(:one)
    @existing_source = sources(:huggingface_forum)
  end

  test "should not allow duplicate URLs" do
    duplicate_source = Source.new(
      name: "Duplicate HuggingFace",
      source_type: "discourse",
      url: @existing_source.url,
      active: true
    )
    
    assert_not duplicate_source.valid?
    assert_includes duplicate_source.errors[:url], "has already been added"
  end

  test "should not allow duplicate URLs with different case" do
    # Update the existing source to have a lowercase URL
    @existing_source.update_column(:url, "https://discuss.huggingface.co")
    
    duplicate_source = Source.new(
      name: "Duplicate HuggingFace",
      source_type: "discourse",
      url: "HTTPS://DISCUSS.HUGGINGFACE.CO",
      active: true
    )
    
    assert_not duplicate_source.valid?
    assert_includes duplicate_source.errors[:url], "has already been added"
  end

  test "should allow different URLs" do
    new_source = Source.new(
      name: "Different Forum",
      source_type: "discourse",
      url: "https://different-forum.example.com",
      active: true
    )
    
    assert new_source.valid?
  end

  test "should allow updating a source without changing URL" do
    @existing_source.name = "Updated Name"
    assert @existing_source.valid?
    assert @existing_source.save
  end

  test "should not allow updating a source to have duplicate URL" do
    other_source = sources(:pytorch_forum)
    
    other_source.url = @existing_source.url
    assert_not other_source.valid?
    assert_includes other_source.errors[:url], "has already been added"
  end

  test "database should enforce URL uniqueness" do
    # Create a source with raw SQL to bypass validations
    Source.connection.execute(<<-SQL)
      INSERT INTO sources (name, source_type, url, active, created_at, updated_at)
      VALUES ('Test Source', 'rss', 'https://unique-test-url.com', 1, datetime('now'), datetime('now'))
    SQL
    
    # Try to create another with the same URL
    assert_raises(ActiveRecord::RecordNotUnique) do
      Source.connection.execute(<<-SQL)
        INSERT INTO sources (name, source_type, url, active, created_at, updated_at)
        VALUES ('Another Source', 'rss', 'https://unique-test-url.com', 1, datetime('now'), datetime('now'))
      SQL
    end
  end
end