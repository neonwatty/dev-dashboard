# Mobile-Responsive ViewComponents

This directory contains mobile-responsive ViewComponents that provide consistent, touch-friendly UI patterns across the application.

## Base Component

All components inherit from `MobileResponsiveComponent`, which provides utility methods for building mobile-first layouts.

### Key Features

- **Touch-friendly sizing**: Minimum 44px touch targets, 48px on very small screens
- **Responsive layouts**: Mobile-first CSS classes with desktop overrides
- **Accessibility**: Proper ARIA attributes and keyboard navigation support
- **Dark mode**: Full dark mode support with Tailwind CSS
- **Performance**: Optimized for mobile devices and slow connections

## Available Components

### PostCardComponent

Displays individual posts with mobile-optimized layouts:
- Vertical layout on mobile, horizontal on desktop
- Touch-friendly action buttons with labels on mobile
- Optimized text sizes and spacing

```erb
<%= render PostCardComponent.new(post: @post, current_user: current_user) %>
```

### MobileModalComponent

Full-screen modals on mobile, centered dialogs on desktop:

```erb
<%= render MobileModalComponent.new(
  id: 'my-modal',
  title: 'Modal Title',
  size: :lg,
  show_footer: true
) do %>
  <p>Modal content goes here</p>
<% end %>
```

### FormFieldComponent

Mobile-optimized form inputs with proper validation display:

```erb
<%= render FormFieldComponent.new(
  label: 'Email Address',
  field_type: :email,
  name: 'user[email]',
  value: @user.email,
  required: true,
  error: @user.errors[:email].first
) %>
```

### ButtonComponent

Consistent, touch-friendly buttons:

```erb
<%= render ButtonComponent.new(
  style: :primary,
  size: :lg,
  icon: :check,
  full_width: true
) do %>
  Save Changes
<% end %>
```

## Helper Methods

The base component provides numerous helper methods:

```ruby
# Responsive classes
responsive_classes(mobile_classes: "flex-col", desktop_classes: "flex-row")
# => "flex-col sm:flex-row"

# Touch targets
touch_target_classes
# => "min-h-[44px] min-w-[44px] max-[768px]:min-h-[48px] max-[768px]:min-w-[48px] flex items-center justify-center"

# Mobile inputs
mobile_input_classes
# => "min-h-[48px] text-base sm:text-sm focus:ring-2 focus:ring-blue-500 focus:border-blue-500"

# Responsive text
responsive_text_size(mobile_size: "text-lg", desktop_size: "text-xl")
# => "text-lg sm:text-xl"

# Line clamping
line_clamp_classes(lines: 3, mobile_lines: 2)
# => "line-clamp-2 sm:line-clamp-3"
```

## Creating New Components

Use the custom generator to create mobile-responsive components:

```bash
rails generate component card_header --mobile-responsive --stimulus --preview
```

This generates:
- `app/components/card_header_component.rb` - Component class
- `app/components/card_header_component.html.erb` - Template
- `app/javascript/controllers/card-header_controller.js` - Stimulus controller
- `test/components/previews/card_header_component_preview.rb` - Preview
- `test/components/card_header_component_test.rb` - Tests

## Best Practices

### Mobile-First Design

Always start with mobile layouts and enhance for desktop:

```ruby
def container_classes
  [
    "flex flex-col", # Mobile: stack vertically
    "sm:flex-row",   # Desktop: arrange horizontally
    "gap-4",         # Consistent spacing
    mobile_padding_classes # Responsive padding
  ].join(" ")
end
```

### Touch Targets

Ensure all interactive elements meet accessibility requirements:

```ruby
def button_classes
  [
    mobile_button_classes(style: :primary),
    touch_target_classes # Minimum 44px
  ].join(" ")
end
```

### Performance

- Use `responsive_classes` to reduce CSS duplication
- Leverage helper methods for consistent patterns
- Consider mobile device capabilities (slower CPUs, limited bandwidth)

### Testing

Test components across different viewport sizes:

```ruby
class MyComponentTest < ViewComponent::TestCase
  def test_mobile_layout
    with_request_url("/") do
      render_inline MyComponent.new
      
      # Assert mobile-specific classes
      assert_selector ".flex-col"
      assert_selector ".sm\\\\:flex-row"
    end
  end
end
```

## Accessibility

All components follow WCAG 2.1 AA guidelines:

- **Touch targets**: Minimum 44px for finger taps
- **Color contrast**: Sufficient contrast in light and dark modes
- **Keyboard navigation**: Full keyboard accessibility
- **Screen readers**: Proper ARIA labels and semantic HTML
- **Focus management**: Visible focus indicators

## Browser Support

Components are tested and optimized for:

- **Mobile**: iOS Safari 12+, Chrome Mobile 90+
- **Desktop**: Chrome 90+, Firefox 88+, Safari 14+
- **Touch devices**: Tablets and smartphones
- **Reduced motion**: Respects `prefers-reduced-motion`

## Contributing

When adding new components:

1. Inherit from `MobileResponsiveComponent`
2. Use mobile-first CSS patterns
3. Include comprehensive tests
4. Add component previews
5. Update this documentation