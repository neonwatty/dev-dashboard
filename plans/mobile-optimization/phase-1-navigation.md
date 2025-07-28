# Phase 1: Mobile Navigation & Layout Foundation

## Overview

This phase establishes the foundational mobile navigation system and responsive layout structure. All desktop functionality will remain intact while adding mobile-specific enhancements.

## Primary Agents

- **Lead**: `tailwind-css-expert` (UI implementation)
- **Support**: `javascript-package-expert` (interactions)
- **Handoff**: `test-runner-fixer` (validation)

## Tasks

### 1.1 Mobile Navigation Menu

**Agent**: `tailwind-css-expert` + `javascript-package-expert`

#### Requirements
- Hamburger menu icon (top-right on mobile)
- Slide-out drawer from right side
- Overlay backdrop with click-to-close
- Smooth animations (300ms transitions)
- Accessible (ARIA labels, keyboard navigation)

#### Implementation Details

**Files to modify:**
- `app/views/layouts/application.html.erb`
- `app/javascript/controllers/mobile_menu_controller.js` (new)
- `app/assets/stylesheets/mobile_navigation.css` (new)

**Navigation structure:**
```erb
<!-- Mobile menu button (visible only on mobile) -->
<button class="md:hidden" data-controller="mobile-menu" data-action="click->mobile-menu#toggle">
  <!-- Hamburger icon -->
</button>

<!-- Mobile navigation drawer -->
<div data-mobile-menu-target="drawer" class="fixed inset-y-0 right-0 transform translate-x-full">
  <!-- Menu items -->
</div>
```

**Stimulus controller features:**
- Toggle menu open/close
- Handle backdrop clicks
- Trap focus when open
- Close on escape key
- Prevent body scroll when open

### 1.2 Bottom Navigation Bar

**Agent**: `tailwind-css-expert`

#### Requirements
- Fixed bottom navigation for primary actions
- 3-4 main items max
- Active state indicators
- Safe area padding for devices with home indicators

#### Implementation
```erb
<!-- Bottom navigation (mobile only) -->
<nav class="md:hidden fixed bottom-0 inset-x-0 bg-white dark:bg-gray-800 border-t safe-area-padding-bottom">
  <div class="grid grid-cols-3">
    <!-- Dashboard -->
    <a href="/" class="flex flex-col items-center py-2">
      <svg><!-- icon --></svg>
      <span class="text-xs mt-1">Dashboard</span>
    </a>
    <!-- Sources -->
    <!-- Analysis -->
  </div>
</nav>
```

### 1.3 Responsive Container System

**Agent**: `tailwind-css-expert`

#### Current Issues
- Fixed `max-w-7xl` containers
- Large desktop-focused padding
- Horizontal overflow on mobile

#### Solutions

**Global container updates:**
```erb
<!-- Replace -->
<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

<!-- With -->
<div class="container mx-auto px-4 sm:px-6 lg:px-8 max-w-full lg:max-w-7xl">
```

**Responsive spacing utility classes:**
```scss
// Add to Tailwind config
@layer utilities {
  .mobile-padding {
    @apply px-4 py-4 sm:px-6 sm:py-6 lg:px-8 lg:py-8;
  }
  
  .mobile-spacing {
    @apply space-y-4 sm:space-y-6 lg:space-y-8;
  }
}
```

### 1.4 Touch-Friendly Navigation Elements

**Agent**: `tailwind-css-expert`

#### Requirements
- Minimum 44px touch targets
- Adequate spacing between clickable elements
- Visual feedback on touch
- Larger fonts for readability

#### Updates needed:
1. Navigation links: increase padding and font size
2. Dropdown menus: convert to full-screen modals on mobile
3. Tab navigation: horizontal scrollable on mobile
4. Breadcrumbs: collapsible on mobile

### 1.5 Responsive Header Optimization

**Agent**: `tailwind-css-expert`

#### Mobile header changes:
- Sticky header with scroll shadow
- Condensed layout (single row)
- Logo + hamburger menu only
- Hide secondary navigation items

```erb
<nav class="sticky top-0 z-40 bg-white dark:bg-gray-800 shadow-sm">
  <div class="container mx-auto px-4">
    <div class="flex justify-between items-center h-14">
      <!-- Logo -->
      <div class="flex items-center">
        <!-- Simplified logo for mobile -->
      </div>
      
      <!-- Mobile menu button -->
      <button class="md:hidden">
        <!-- Hamburger -->
      </button>
      
      <!-- Desktop nav (hidden on mobile) -->
      <div class="hidden md:flex">
        <!-- Existing desktop navigation -->
      </div>
    </div>
  </div>
</nav>
```

## Testing Requirements

### Manual Testing Checklist
- [ ] Menu opens/closes smoothly
- [ ] Backdrop prevents interaction with content
- [ ] Focus is trapped in menu when open
- [ ] All navigation items are accessible
- [ ] Bottom nav doesn't overlap content
- [ ] No horizontal scrolling on any page

### Automated Tests
```ruby
# spec/system/mobile_navigation_spec.rb
RSpec.describe "Mobile Navigation", type: :system do
  context "on mobile viewport" do
    before { page.driver.browser.manage.window.resize_to(375, 667) }
    
    it "shows hamburger menu"
    it "opens navigation drawer on click"
    it "closes drawer on backdrop click"
    it "shows bottom navigation"
    it "highlights active nav item"
  end
end
```

## Handoff Protocol

### Completion Checklist
- [ ] All navigation elements responsive
- [ ] Touch targets ≥ 44px
- [ ] No horizontal scroll issues
- [ ] Animations smooth (60fps)
- [ ] Dark mode fully supported
- [ ] Tests passing

### Data for Next Phase
```json
{
  "completed_components": [
    "mobile_menu_controller",
    "bottom_navigation", 
    "responsive_containers"
  ],
  "css_utilities_added": [
    "mobile-padding",
    "mobile-spacing",
    "safe-area-padding"
  ],
  "breakpoint_system": "mobile-first",
  "ready_for": "component_optimization"
}
```

### Next Agent: `tailwind-css-expert`
Continue with Phase 2: Component Mobile Optimization

## Implementation Commands

```bash
# Start implementation
Task(description="Phase 1 Mobile Navigation",
     subagent_type="tailwind-css-expert",
     prompt="Implement mobile navigation from plans/mobile-optimization/phase-1-navigation.md. 
             Create hamburger menu, bottom nav, and responsive containers.
             Handoff to javascript-package-expert for menu interactions.")

# JavaScript interactions
Task(description="Mobile menu interactions",
     subagent_type="javascript-package-expert", 
     prompt="Add Stimulus controller for mobile menu with animations, 
             backdrop, focus trap, and keyboard support.")

# Testing
Task(description="Test mobile navigation",
     subagent_type="test-runner-fixer",
     prompt="Write and run tests for mobile navigation components.
             Verify touch targets and responsive behavior.")
```