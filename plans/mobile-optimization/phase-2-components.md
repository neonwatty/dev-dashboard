# Phase 2: Component Mobile Optimization

## Overview

This phase focuses on optimizing individual UI components for mobile devices, ensuring all content is easily consumable and interactive on small screens.

## Primary Agents

- **Lead**: `tailwind-css-expert` (component redesign)
- **Support**: `ruby-rails-expert` (ViewComponent updates)
- **Handoff**: `javascript-package-expert` (interactions)

## Tasks

### 2.1 Post Card Mobile Redesign

**Agent**: `tailwind-css-expert` → `ruby-rails-expert`

#### Current Issues
- Horizontal layout with fixed widths
- Small action buttons (16px icons)
- Multiple columns don't stack
- Tags can overflow

#### Mobile Design Requirements

**Layout changes:**
```erb
<!-- app/views/posts/_post_card.html.erb -->
<div class="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-4 sm:p-6">
  <!-- Mobile: Vertical layout -->
  <div class="flex flex-col sm:flex-row sm:items-start sm:gap-4">
    
    <!-- Source Badge (top on mobile) -->
    <div class="flex items-center gap-3 mb-3 sm:mb-0 sm:flex-col sm:w-20">
      <div class="w-10 h-10 sm:w-12 sm:h-12 rounded-lg">
        <!-- icon -->
      </div>
      <div class="flex-1 sm:text-center">
        <div class="text-sm font-semibold"><%= post.source_type %></div>
        <div class="text-xs text-gray-500"><%= post.source_name %></div>
      </div>
    </div>
    
    <!-- Content -->
    <div class="flex-1">
      <!-- Title - larger on mobile -->
      <h3 class="text-base sm:text-lg font-semibold mb-1">
        <%= link_to post.title, post.url %>
      </h3>
      
      <!-- Meta - single line on mobile -->
      <div class="text-sm text-gray-500 mb-2">
        <%= post.author %> • <%= time_ago_in_words(post.posted_at) %>
      </div>
      
      <!-- Summary - show less on mobile -->
      <p class="text-sm text-gray-600 line-clamp-2 sm:line-clamp-3 mb-3">
        <%= post.summary %>
      </p>
      
      <!-- Tags - horizontal scroll on mobile -->
      <div class="flex gap-2 overflow-x-auto pb-2 -mx-4 px-4 sm:mx-0 sm:px-0 sm:flex-wrap">
        <% post.tags_array.each do |tag| %>
          <span class="inline-flex shrink-0 px-2 py-1 text-xs">#<%= tag %></span>
        <% end %>
      </div>
    </div>
  </div>
  
  <!-- Actions - full width on mobile -->
  <div class="flex items-center justify-between mt-4 pt-4 border-t">
    <!-- Status -->
    <span class="text-sm font-medium <%= status_color(post.status) %>">
      <%= post.status.titleize %>
    </span>
    
    <!-- Action buttons - larger with labels -->
    <div class="flex gap-2">
      <button class="flex items-center gap-1 px-3 py-2 text-sm rounded-lg hover:bg-gray-100">
        <svg class="w-5 h-5"><!-- check icon --></svg>
        <span class="hidden sm:inline">Read</span>
      </button>
      <button class="flex items-center gap-1 px-3 py-2 text-sm rounded-lg hover:bg-gray-100">
        <svg class="w-5 h-5"><!-- x icon --></svg>
        <span class="hidden sm:inline">Clear</span>
      </button>
    </div>
  </div>
</div>
```

**Key changes:**
- Vertical layout on mobile
- Larger touch targets (min 44px)
- Horizontal scroll for tags
- Action buttons with optional labels
- Reduced content density

### 2.2 Form Mobile Optimization

**Agent**: `tailwind-css-expert` → `ruby-rails-expert`

#### Form Components to Update

**Input fields:**
```erb
<!-- Before -->
<%= form.text_field :title, class: "form-input" %>

<!-- After -->
<%= form.text_field :title, 
    class: "w-full px-4 py-3 text-base border rounded-lg focus:ring-2",
    autocomplete: "off",
    autocapitalize: "off" %>
```

**Mobile form improvements:**
1. Larger input fields (min height 48px)
2. Proper input types (email, tel, number)
3. Autocomplete attributes
4. Input mode hints (numeric, decimal)
5. Clear error messages below fields

**Select dropdowns:**
```erb
<!-- Convert to mobile-friendly select -->
<div class="relative">
  <%= form.select :status, options, {}, 
      class: "w-full px-4 py-3 pr-10 text-base appearance-none" %>
  <div class="absolute inset-y-0 right-0 flex items-center pr-3 pointer-events-none">
    <svg class="w-5 h-5 text-gray-400"><!-- chevron --></svg>
  </div>
</div>
```

**Submit buttons:**
```erb
<%= form.submit "Save Changes", 
    class: "w-full sm:w-auto px-6 py-3 text-base font-medium rounded-lg",
    data: { disable_with: "Saving..." } %>
```

### 2.3 Smart Filters Mobile UI

**Agent**: `tailwind-css-expert`

#### Current Implementation
- Multiple dropdowns in a row
- Desktop-oriented layout
- Small touch targets

#### Mobile Design

**Collapsible filter panel:**
```erb
<!-- app/views/posts/_smart_filters.html.erb -->
<div data-controller="mobile-filters" class="mb-6">
  <!-- Filter toggle button (mobile only) -->
  <button class="md:hidden w-full flex items-center justify-between p-4 bg-white rounded-lg"
          data-action="click->mobile-filters#toggle">
    <span class="font-medium">Filters</span>
    <div class="flex items-center gap-2">
      <span class="text-sm text-gray-500" data-mobile-filters-target="count">
        <!-- Active filter count -->
      </span>
      <svg class="w-5 h-5"><!-- chevron --></svg>
    </div>
  </button>
  
  <!-- Filter panel -->
  <div class="mt-4 md:mt-0 hidden md:block" data-mobile-filters-target="panel">
    <div class="bg-white rounded-lg p-4">
      <!-- Mobile: Stack filters vertically -->
      <div class="space-y-3 md:flex md:gap-3 md:space-y-0">
        <!-- Individual filters -->
      </div>
      
      <!-- Active filters as chips -->
      <div class="flex flex-wrap gap-2 mt-4">
        <% if params[:keyword].present? %>
          <span class="inline-flex items-center gap-1 px-3 py-1 bg-blue-100 rounded-full text-sm">
            <%= params[:keyword] %>
            <button data-action="click->mobile-filters#remove">×</button>
          </span>
        <% end %>
      </div>
      
      <!-- Clear all button -->
      <% if has_active_filters? %>
        <button class="mt-4 w-full text-center text-sm text-blue-600">
          Clear all filters
        </button>
      <% end %>
    </div>
  </div>
</div>
```

### 2.4 Table Mobile Views

**Agent**: `tailwind-css-expert` → `ruby-rails-expert`

#### Strategy: Card-based layout on mobile

**Sources table example:**
```erb
<!-- app/views/sources/index.html.erb -->
<!-- Desktop: Table -->
<div class="hidden md:block overflow-x-auto">
  <table class="min-w-full">
    <!-- existing table -->
  </table>
</div>

<!-- Mobile: Cards -->
<div class="md:hidden space-y-4">
  <% @sources.each do |source| %>
    <div class="bg-white rounded-lg p-4 shadow-sm">
      <div class="flex items-start justify-between mb-2">
        <h3 class="font-medium"><%= source.name %></h3>
        <%= render 'status_badge', source: source %>
      </div>
      
      <dl class="space-y-1 text-sm">
        <div class="flex justify-between">
          <dt class="text-gray-500">Type:</dt>
          <dd><%= source.source_type %></dd>
        </div>
        <div class="flex justify-between">
          <dt class="text-gray-500">Posts:</dt>
          <dd><%= source.posts_count %></dd>
        </div>
        <div class="flex justify-between">
          <dt class="text-gray-500">Last updated:</dt>
          <dd><%= time_ago_in_words(source.last_fetched_at) %> ago</dd>
        </div>
      </dl>
      
      <div class="flex gap-2 mt-3 pt-3 border-t">
        <%= link_to "View", source, class: "flex-1 text-center py-2 text-sm" %>
        <%= link_to "Edit", edit_source_path(source), class: "flex-1 text-center py-2 text-sm" %>
      </div>
    </div>
  <% end %>
</div>
```

### 2.5 Modal & Dialog Optimization

**Agent**: `tailwind-css-expert`

#### Mobile modal requirements
- Full screen on mobile
- Slide up animation
- Close button in header
- Scrollable content area

**Implementation:**
```erb
<!-- Responsive modal -->
<div class="fixed inset-0 z-50 overflow-y-auto" data-controller="modal">
  <!-- Backdrop -->
  <div class="fixed inset-0 bg-black bg-opacity-50"></div>
  
  <!-- Modal -->
  <div class="flex min-h-screen items-end sm:items-center justify-center">
    <div class="relative w-full sm:max-w-lg sm:mx-4 bg-white sm:rounded-lg 
                max-h-screen sm:max-h-[90vh] flex flex-col">
      
      <!-- Header - sticky on mobile -->
      <div class="sticky top-0 flex items-center justify-between p-4 border-b bg-white sm:rounded-t-lg">
        <h3 class="text-lg font-semibold">Modal Title</h3>
        <button data-action="click->modal#close" class="p-2">
          <svg class="w-6 h-6"><!-- x icon --></svg>
        </button>
      </div>
      
      <!-- Content - scrollable -->
      <div class="flex-1 overflow-y-auto p-4">
        <!-- Modal content -->
      </div>
      
      <!-- Footer - sticky on mobile -->
      <div class="sticky bottom-0 p-4 border-t bg-white sm:rounded-b-lg">
        <!-- Action buttons -->
      </div>
    </div>
  </div>
</div>
```

## ViewComponent Updates

**Agent**: `ruby-rails-expert`

### Component Generator Updates

Create mobile-responsive ViewComponent template:

```ruby
# app/components/mobile_responsive_component.rb
class MobileResponsiveComponent < ViewComponent::Base
  def initialize(mobile_class: "", desktop_class: "", **options)
    @mobile_class = mobile_class
    @desktop_class = desktop_class
    @options = options
  end
  
  private
  
  def responsive_classes
    [
      @mobile_class,
      @desktop_class.split(" ").map { |c| "sm:#{c}" }
    ].flatten.join(" ")
  end
end
```

## Testing Checklist

### Visual Testing
- [ ] All text readable without zooming
- [ ] No horizontal scrolling
- [ ] Touch targets ≥ 44px
- [ ] Forms usable with virtual keyboard
- [ ] Modals accessible on small screens

### Component Testing
```ruby
# spec/components/mobile_responsive_spec.rb
RSpec.describe "Mobile Responsive Components" do
  it "renders mobile layout at small viewport"
  it "stacks elements vertically on mobile"
  it "shows desktop layout at larger viewport"
  it "maintains functionality across breakpoints"
end
```

## Handoff Protocol

### Completion Data
```json
{
  "updated_components": [
    "post_card",
    "smart_filters",
    "forms",
    "tables_to_cards",
    "modals"
  ],
  "responsive_patterns": {
    "layout": "vertical_stack_mobile",
    "navigation": "horizontal_scroll_tags",
    "tables": "card_based_mobile",
    "modals": "fullscreen_mobile"
  },
  "ready_for": "touch_interactions"
}
```

### Next Phase: Touch Interactions
Hand off to `javascript-package-expert` for Phase 3

## Implementation Commands

```bash
# Start component updates
Task(description="Mobile component optimization",
     subagent_type="tailwind-css-expert",
     prompt="Update all components from phase-2-components.md for mobile.
             Focus on post cards, forms, filters, and tables.")

# ViewComponent updates  
Task(description="Update ViewComponents for mobile",
     subagent_type="ruby-rails-expert",
     prompt="Create mobile-responsive ViewComponent patterns.
             Update existing components with responsive variants.")

# Test components
Task(description="Test mobile components",
     subagent_type="test-runner-fixer",
     prompt="Write component tests for mobile viewports.
             Verify responsive behavior and touch targets.")
```