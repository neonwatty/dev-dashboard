require "test_helper"

class StatusBadgeTest < ActionView::TestCase
  def setup
    @source = sources(:huggingface_forum)
  end

  test "renders refreshing status with animation" do
    @source.status = "refreshing..."
    rendered = render partial: "sources/status_badge", locals: { source: @source }
    
    assert_match /turbo-frame.*source_#{@source.id}_status/, rendered
    assert_match /bg-yellow-500/, rendered
    assert_match /animate-pulse/, rendered
    assert_match /Refreshing\.\.\./, rendered
  end

  test "renders ok status with green badge" do
    @source.status = "ok"
    rendered = render partial: "sources/status_badge", locals: { source: @source }
    
    assert_match /bg-green-500/, rendered
    assert_match /ok/, rendered
    assert_no_match /animate-pulse/, rendered
  end

  test "renders ok status with new items count" do
    @source.status = "ok (5 new)"
    rendered = render partial: "sources/status_badge", locals: { source: @source }
    
    assert_match /bg-green-500/, rendered
    assert_match /ok \(5 new\)/, rendered
  end

  test "renders error status with red badge" do
    @source.status = "error: connection failed"
    rendered = render partial: "sources/status_badge", locals: { source: @source }
    
    assert_match /bg-red-500/, rendered
    assert_match /Error/, rendered
    assert_match /title=.*connection failed/, rendered
  end

  test "renders unknown status for nil" do
    @source.status = nil
    rendered = render partial: "sources/status_badge", locals: { source: @source }
    
    assert_match /bg-gray-500/, rendered
    assert_match /Unknown/, rendered
  end

  test "truncates long error messages" do
    @source.status = "error: " + "x" * 100
    rendered = render partial: "sources/status_badge", locals: { source: @source }
    
    assert_match /Error/, rendered
    # The full text is in the title attribute for tooltip
    assert_match /title=.*x+/, rendered
  end

  test "wraps content in turbo frame with correct id" do
    rendered = render partial: "sources/status_badge", locals: { source: @source }
    
    assert_select "turbo-frame#source_#{@source.id}_status"
    assert_select "turbo-frame span.inline-block"
  end
end