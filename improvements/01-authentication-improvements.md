# Authentication Improvements

## Overview
Enhance the authentication flow and user experience for unauthenticated users.

## Tasks

### TASK-AUTH-001: Add Authentication Required Message
**Priority**: High  
**Type**: UX Enhancement  
**Estimated Effort**: Small (1-2 hours)

**Description**: When an unauthenticated user clicks on protected routes (Sources, Analysis), show a clear message explaining that authentication is required instead of immediately redirecting to the sign-in page.

**Technical Requirements**:
- Add a flash message or modal before redirect
- Message should explain: "Authentication required to access [feature name]"
- Include options: "Sign In" or "Learn More"
- Store the intended destination in session for post-login redirect

**Acceptance Criteria**:
- [ ] Flash message appears when clicking protected links
- [ ] Message clearly explains why authentication is needed
- [ ] User is redirected to original destination after login
- [ ] Works on both desktop and mobile views

**Files to Modify**:
- `app/controllers/concerns/authentication.rb`
- `app/controllers/sources_controller.rb` 
- `app/controllers/analysis_controller.rb`
- `app/views/shared/_flash_notification.html.erb`

---

### TASK-AUTH-002: Implement Guest/Demo Mode
**Priority**: Medium  
**Type**: Feature  
**Estimated Effort**: Medium (4-6 hours)

**Description**: Create a guest/demo mode that allows users to explore key features with sample data before signing up.

**Technical Requirements**:
- Create a demo data set with sample posts and sources
- Implement read-only mode for guest users
- Show "Sign up to save your preferences" prompts
- Auto-expire guest sessions after 30 minutes
- Track guest → registered conversion metrics

**Acceptance Criteria**:
- [ ] "Try Demo" button appears on landing page
- [ ] Guest users can view sample posts and sources
- [ ] Guest users cannot modify data
- [ ] Clear prompts to sign up throughout the experience
- [ ] Smooth transition from guest to registered user

**Files to Create/Modify**:
- `app/controllers/demo_controller.rb` (new)
- `app/models/guest_user.rb` (new)
- `app/views/posts/landing.html.erb`
- `db/seeds/demo_data.rb` (new)
- `config/routes.rb`

---

### TASK-AUTH-003: Improve Sign-In/Sign-Up Flow
**Priority**: Medium  
**Type**: UX Enhancement  
**Estimated Effort**: Small (2-3 hours)

**Description**: Enhance the authentication forms with better error handling and social login options preparation.

**Technical Requirements**:
- Add inline validation for email format
- Show password strength indicator
- Prepare UI for future OAuth providers (GitHub, Google)
- Add "Remember me" checkbox functionality
- Implement better error messages for failed login attempts

**Acceptance Criteria**:
- [ ] Real-time email validation
- [ ] Password strength indicator on sign-up
- [ ] Clear, actionable error messages
- [ ] "Remember me" persists sessions appropriately
- [ ] OAuth provider buttons ready (but disabled)

**Files to Modify**:
- `app/views/sessions/new.html.erb`
- `app/views/registrations/new.html.erb`
- `app/controllers/sessions_controller.rb`
- `app/javascript/controllers/form_validation_controller.js` (new)

## Testing Requirements
- Test all authentication flows on mobile and desktop
- Verify protected route handling
- Test session persistence and expiration
- Ensure error messages are clear and helpful
- Verify demo mode limitations

## Dependencies
- No external dependencies
- Consider adding devise gem for OAuth in future phase

## Notes
- Focus on clear communication about why authentication is needed
- Guest mode should showcase key features without overwhelming new users
- Consider A/B testing demo mode conversion rates