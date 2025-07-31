# Mobile Enhancements

## Overview
Improve mobile user experience with gesture support, enhanced interactions, and visual feedback.

## Tasks

### TASK-MOB-001: Add Swipe Gesture Support for Mobile Menu
**Priority**: Medium  
**Type**: Feature Enhancement  
**Estimated Effort**: Medium (3-4 hours)

**Description**: Implement swipe-to-close gesture for the mobile navigation drawer, providing a more natural mobile interaction pattern.

**Technical Requirements**:
- Detect swipe-right gesture on drawer
- Smooth animation during swipe
- Threshold detection (>50% swipe = close)
- Visual feedback during swipe (drawer follows finger)
- Fallback for non-touch devices

**Acceptance Criteria**:
- [ ] Swipe right closes the drawer smoothly
- [ ] Partial swipes snap back if under threshold
- [ ] No interference with vertical scrolling
- [ ] Works with existing touch feedback
- [ ] Performance remains smooth (60fps)

**Files to Modify**:
- `app/javascript/controllers/mobile_menu_controller.js`
- `app/javascript/utils/swipe_handler.js` (new)
- `app/assets/stylesheets/application.css`

---

### TASK-MOB-002: Add Visual Active State Indicator for Bottom Navigation
**Priority**: Low  
**Type**: Visual Enhancement  
**Estimated Effort**: Small (1 hour)

**Description**: Enhance the existing bottom navigation active states with additional visual feedback.

**Technical Requirements**:
- Add subtle scale animation on tap
- Implement ripple effect on selection
- Add badge for unread counts (future-ready)
- Ensure color contrast meets WCAG standards

**Acceptance Criteria**:
- [ ] Active state is immediately visible
- [ ] Tap feedback is responsive
- [ ] Animation doesn't cause layout shift
- [ ] Works in both light and dark modes

**Files to Modify**:
- `app/assets/stylesheets/application.css` (bottom-nav section)
- `app/javascript/controllers/bottom_nav_controller.js` (new)

---

### TASK-MOB-003: Implement Haptic Feedback for Mobile Interactions
**Priority**: Low  
**Type**: Feature Enhancement  
**Estimated Effort**: Small (2 hours)

**Description**: Add subtle haptic feedback for key mobile interactions using the Vibration API.

**Technical Requirements**:
- Light haptic on button taps (10ms)
- Medium haptic on menu open/close (20ms)
- Strong haptic on destructive actions (30ms)
- Settings toggle to disable haptics
- Feature detection for API support

**Acceptance Criteria**:
- [ ] Haptic feedback on supported devices
- [ ] No errors on unsupported devices
- [ ] User can disable in settings
- [ ] Feedback feels natural, not intrusive

**Files to Modify**:
- `app/javascript/utils/haptics.js`
- `app/javascript/controllers/touch_feedback_controller.js`
- `app/views/settings/edit.html.erb`
- `app/models/user_setting.rb`

---

### TASK-MOB-004: Add Pull-to-Refresh for Post Lists
**Priority**: Medium  
**Type**: Feature  
**Estimated Effort**: Medium (4 hours)

**Description**: Implement native-feeling pull-to-refresh on mobile post lists.

**Technical Requirements**:
- Detect pull gesture at scroll top
- Show loading indicator during refresh
- Smooth elastic animation
- Trigger source refresh on release
- Prevent during active scroll

**Acceptance Criteria**:
- [ ] Natural pull gesture detection
- [ ] Visual feedback during pull
- [ ] Refreshes data on release
- [ ] Handles errors gracefully
- [ ] Doesn't interfere with normal scrolling

**Files to Modify**:
- `app/javascript/controllers/pull_to_refresh_controller.js`
- `app/views/posts/index.html.erb`
- `app/assets/stylesheets/application.css`

---

### TASK-MOB-005: Optimize Touch Targets for Mobile
**Priority**: High  
**Type**: Accessibility  
**Estimated Effort**: Small (2 hours)

**Description**: Ensure all interactive elements meet minimum touch target size requirements (44x44px).

**Technical Requirements**:
- Audit all buttons, links, and interactive elements
- Add padding where needed without breaking layout
- Ensure tap areas don't overlap
- Test on various mobile devices

**Acceptance Criteria**:
- [ ] All touch targets ≥ 44x44px
- [ ] No accidental taps on adjacent elements
- [ ] Visual appearance remains consistent
- [ ] Works across all mobile breakpoints

**Files to Modify**:
- `app/assets/stylesheets/application.css`
- Various view templates as needed

---

### TASK-MOB-006: Add Mobile-Specific Loading States
**Priority**: Low  
**Type**: UX Enhancement  
**Estimated Effort**: Small (2 hours)

**Description**: Implement skeleton screens and progressive loading for better perceived performance on mobile.

**Technical Requirements**:
- Skeleton screens for post cards
- Shimmer effect during load
- Progressive image loading
- Smooth transitions when content loads

**Acceptance Criteria**:
- [ ] Skeleton screens match actual content layout
- [ ] Loading feels faster (perceived performance)
- [ ] No layout shift when content loads
- [ ] Works offline (shows cached skeletons)

**Files to Create/Modify**:
- `app/views/posts/_skeleton_card.html.erb` (new)
- `app/javascript/controllers/skeleton_loader_controller.js` (new)
- `app/assets/stylesheets/components/skeleton.css` (new)

## Testing Requirements
- Test on real devices (iOS Safari, Android Chrome)
- Verify touch gestures don't conflict
- Test with screen readers enabled
- Verify performance on low-end devices
- Test offline/slow network scenarios

## Dependencies
- Vibration API (for haptics)
- Touch Events API
- IntersectionObserver (for progressive loading)

## Notes
- Prioritize natural, native-feeling interactions
- Keep animations under 300ms for responsiveness
- Consider battery impact of haptic feedback
- Test thoroughly on older devices