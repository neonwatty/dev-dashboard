# Responsive Layout Improvements

## Overview
Optimize layout and content presentation across all device sizes, with special attention to large screens and edge cases.

## Tasks

### TASK-RESP-001: Add Max-Width Container for Large Screens
**Priority**: High  
**Type**: Layout Enhancement  
**Estimated Effort**: Small (2 hours)

**Description**: Implement maximum width constraints for content on large screens (>1920px) to maintain readability.

**Technical Requirements**:
- Max-width: 1440px for main content
- Centered container with padding
- Full-width backgrounds maintained
- Responsive breakpoints adjustment
- Consistent spacing on sides

**Acceptance Criteria**:
- [ ] Content doesn't stretch too wide
- [ ] Backgrounds remain full width
- [ ] Smooth transition at breakpoint
- [ ] Works with all page layouts
- [ ] No horizontal scroll

**Files to Modify**:
- `app/assets/stylesheets/application.css`
- `app/views/layouts/application.html.erb`
- `config/tailwind.config.js`

---

### TASK-RESP-002: Optimize Grid Layouts for Tablets
**Priority**: Medium  
**Type**: Responsive Design  
**Estimated Effort**: Small (2 hours)

**Description**: Improve grid layouts specifically for tablet devices (768px - 1024px).

**Technical Requirements**:
- 2-column grid for feature cards
- Adjusted spacing for tablets
- Proper touch targets maintained
- Landscape orientation support
- No content overflow

**Acceptance Criteria**:
- [ ] Grids adapt smoothly to tablet
- [ ] Content remains readable
- [ ] Touch targets stay accessible
- [ ] Works in both orientations
- [ ] No layout breaking

**Files to Modify**:
- `app/views/posts/landing.html.erb`
- `app/assets/stylesheets/application.css`
- Various grid-based components

---

### TASK-RESP-003: Implement Responsive Typography System
**Priority**: Medium  
**Type**: Typography  
**Estimated Effort**: Medium (3 hours)

**Description**: Create a fluid typography system that scales smoothly across all viewports.

**Technical Requirements**:
- CSS clamp() for fluid sizing
- Modular scale system
- Minimum and maximum sizes
- Proper line height scaling
- Consistent vertical rhythm

**Acceptance Criteria**:
- [ ] Text scales smoothly
- [ ] Always readable size
- [ ] Maintains hierarchy
- [ ] No text overflow
- [ ] Works with user zoom

**Files to Create/Modify**:
- `app/assets/stylesheets/base/typography.css`
- `config/tailwind.config.js`
- Root CSS variables

---

### TASK-RESP-004: Fix Mobile Navigation Overflow
**Priority**: High  
**Type**: Bug Fix  
**Estimated Effort**: Small (1 hour)

**Description**: Ensure mobile navigation drawer handles long content without breaking.

**Technical Requirements**:
- Scroll within drawer sections
- Fixed header/footer in drawer
- Prevent body scroll when open
- Handle very long email addresses
- Safe area padding for notches

**Acceptance Criteria**:
- [ ] Long content scrolls properly
- [ ] Header/footer stay fixed
- [ ] No double scrollbars
- [ ] Works on all mobile devices
- [ ] Respects safe areas

**Files to Modify**:
- `app/assets/stylesheets/application.css`
- `app/views/layouts/application.html.erb`

---

### TASK-RESP-005: Improve Image Responsiveness
**Priority**: Medium  
**Type**: Performance & Layout  
**Estimated Effort**: Medium (3 hours)

**Description**: Implement responsive images with proper srcset and sizes attributes.

**Technical Requirements**:
- Multiple image sizes generated
- Proper srcset attributes
- Sizes based on layout
- Art direction for key images
- WebP with fallbacks

**Acceptance Criteria**:
- [ ] Images load appropriate size
- [ ] No oversized images on mobile
- [ ] Sharp images on retina
- [ ] Fast loading times
- [ ] Fallbacks work

**Files to Create/Modify**:
- `app/helpers/responsive_image_helper.rb` (new)
- `app/models/concerns/image_variants.rb` (new)
- Various view files with images

---

### TASK-RESP-006: Create Responsive Table Component
**Priority**: Low  
**Type**: Component  
**Estimated Effort**: Medium (4 hours)

**Description**: Build a responsive table component that works well on mobile devices.

**Technical Requirements**:
- Horizontal scroll on mobile
- Sticky first column option
- Card view for narrow screens
- Sortable columns
- Accessible markup

**Acceptance Criteria**:
- [ ] Tables usable on mobile
- [ ] No data loss
- [ ] Clear visual hierarchy
- [ ] Maintains accessibility
- [ ] Smooth transitions

**Files to Create**:
- `app/components/responsive_table_component.rb`
- `app/components/responsive_table_component.html.erb`
- `app/assets/stylesheets/components/table.css`

## Testing Requirements
- Test on various devices and viewports
- Check all breakpoints for issues
- Validate with real content
- Test with browser zoom (up to 200%)
- Orientation change testing

## Dependencies
- CSS Container Queries (with fallback)
- CSS clamp() function
- Intersection Observer

## Notes
- Mobile-first approach for all changes
- Test with real content, not lorem ipsum
- Consider future devices (foldables)
- Maintain performance while adding features