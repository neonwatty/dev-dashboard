# Accessibility Improvements

## Overview
Enhance accessibility to ensure the application is usable by everyone, meeting WCAG 2.1 AA standards.

## Tasks

### TASK-A11Y-001: Add Keyboard Shortcuts System
**Priority**: Medium  
**Type**: Accessibility Feature  
**Estimated Effort**: Medium (4 hours)

**Description**: Implement comprehensive keyboard shortcuts for power users and accessibility needs.

**Technical Requirements**:
- Global shortcuts (/, ?, g+h, g+s)
- List navigation (j/k, arrow keys)
- Action shortcuts (r=refresh, m=mark read)
- Customizable shortcut keys
- Visual shortcut guide modal

**Acceptance Criteria**:
- [ ] All major actions have shortcuts
- [ ] No conflicts with browser shortcuts
- [ ] ? key shows shortcut guide
- [ ] Shortcuts work with screen readers
- [ ] Can be disabled in settings

**Files to Create/Modify**:
- `app/javascript/controllers/keyboard_shortcuts_controller.js` (new)
- `app/views/shared/_keyboard_guide.html.erb` (new)
- `app/models/user_setting.rb`
- `app/views/layouts/application.html.erb`

---

### TASK-A11Y-002: Improve Color Contrast Ratios
**Priority**: High  
**Type**: Visual Accessibility  
**Estimated Effort**: Medium (3 hours)

**Description**: Audit and fix all color combinations to meet WCAG AA standards (4.5:1 for normal text, 3:1 for large text).

**Technical Requirements**:
- Audit current color combinations
- Fix failing contrast ratios
- Maintain brand aesthetic
- Test in both light/dark modes
- Document color system

**Acceptance Criteria**:
- [ ] All text meets WCAG AA contrast
- [ ] Interactive elements have 3:1 ratio
- [ ] Focus indicators are clearly visible
- [ ] Error states use accessible colors
- [ ] Contrast checker passes all pages

**Files to Modify**:
- `config/tailwind.config.js`
- `app/assets/stylesheets/application.css`
- Various component stylesheets

---

### TASK-A11Y-003: Enhance Screen Reader Announcements
**Priority**: High  
**Type**: Screen Reader Support  
**Estimated Effort**: Medium (3 hours)

**Description**: Add proper ARIA live regions and screen reader announcements for dynamic content.

**Technical Requirements**:
- Live region for notifications
- Status updates for async actions
- Loading state announcements
- Error announcements
- Polite vs assertive regions

**Acceptance Criteria**:
- [ ] All dynamic updates announced
- [ ] No repetitive announcements
- [ ] Clear action confirmations
- [ ] Proper region priorities
- [ ] Works with NVDA/JAWS/VoiceOver

**Files to Create/Modify**:
- `app/views/layouts/application.html.erb` (aria-live regions)
- `app/javascript/controllers/screen_reader_controller.js` (new)
- `app/helpers/accessibility_helper.rb` (new)
- Various Turbo Stream responses

---

### TASK-A11Y-004: Improve Form Accessibility
**Priority**: High  
**Type**: Form Enhancement  
**Estimated Effort**: Small (2 hours)

**Description**: Enhance all forms with proper labels, error messages, and keyboard navigation.

**Technical Requirements**:
- All inputs have visible labels
- Error messages linked to fields
- Required fields clearly marked
- Fieldset/legend for groups
- Proper autocomplete attributes

**Acceptance Criteria**:
- [ ] Every input has associated label
- [ ] Errors announced to screen readers
- [ ] Tab order is logical
- [ ] Required fields indicated clearly
- [ ] Works without JavaScript

**Files to Modify**:
- `app/components/form_field_component.rb`
- `app/views/sessions/new.html.erb`
- `app/views/registrations/new.html.erb`
- `app/views/sources/_form.html.erb`

---

### TASK-A11Y-005: Add Skip Navigation Links
**Priority**: Medium  
**Type**: Navigation Aid  
**Estimated Effort**: Small (1 hour)

**Description**: Implement skip links for keyboard users to bypass repetitive navigation.

**Technical Requirements**:
- Skip to main content
- Skip to navigation
- Skip to search (if applicable)
- Visible on focus only
- Proper anchor targets

**Acceptance Criteria**:
- [ ] Skip links appear on tab
- [ ] Links work correctly
- [ ] Styled consistently
- [ ] Don't interfere with layout
- [ ] Work on all pages

**Files to Modify**:
- `app/views/layouts/application.html.erb`
- `app/assets/stylesheets/application.css`

---

### TASK-A11Y-006: Implement Focus Management for SPAs
**Priority**: Medium  
**Type**: SPA Accessibility  
**Estimated Effort**: Medium (3 hours)

**Description**: Properly manage focus when navigating between pages in the Turbo-powered app.

**Technical Requirements**:
- Focus moves to main content on navigation
- Focus returns to trigger on modal close
- Focus trap in modals/drawers
- Maintain focus during updates
- Announce page changes

**Acceptance Criteria**:
- [ ] Focus moves logically
- [ ] No focus loss on navigation
- [ ] Modals trap focus properly
- [ ] Escape key works consistently
- [ ] Page changes announced

**Files to Create/Modify**:
- `app/javascript/controllers/focus_management_controller.js` (new)
- `app/javascript/controllers/mobile_menu_controller.js`
- `app/views/layouts/application.html.erb`

---

### TASK-A11Y-007: Add Reduced Motion Support
**Priority**: Low  
**Type**: Motion Accessibility  
**Estimated Effort**: Small (2 hours)

**Description**: Respect user's motion preferences throughout the application.

**Technical Requirements**:
- Detect prefers-reduced-motion
- Disable non-essential animations
- Maintain functionality
- Instant transitions option
- Settings override

**Acceptance Criteria**:
- [ ] Animations respect preference
- [ ] Functionality unchanged
- [ ] Can override in settings
- [ ] Smooth degradation
- [ ] No JavaScript errors

**Files to Modify**:
- `app/javascript/controllers/application.js`
- `app/assets/stylesheets/application.css`
- Various animation controllers

## Testing Requirements
- Test with NVDA, JAWS, VoiceOver
- Keyboard-only navigation testing
- Automated accessibility testing (axe-core)
- Color contrast validation
- Focus indicator visibility

## Dependencies
- aria-live-announcer library
- axe-core for testing
- focus-trap library

## Notes
- Follow WCAG 2.1 AA guidelines
- Test with real assistive technology
- Consider cognitive accessibility
- Document accessibility features for users