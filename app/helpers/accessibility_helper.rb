# frozen_string_literal: true

# Helper methods for accessibility features including screen reader support
module AccessibilityHelper
  # Generate an ARIA live region announcement
  # @param message [String] The message to announce
  # @param priority [Symbol] :polite, :assertive, or :status
  # @param options [Hash] Additional options
  def screen_reader_announce(message, priority: :polite, **options)
    return '' if message.blank?
    
    content_tag :script, type: 'application/javascript', data: { turbo_temporary: true } do
      javascript_announcement(message, priority, options)
    end
  end
  
  # Generate a polite announcement (doesn't interrupt current speech)
  def announce_politely(message, **options)
    screen_reader_announce(message, priority: :polite, **options)
  end
  
  # Generate an assertive announcement (interrupts current speech)
  def announce_urgently(message, **options)
    screen_reader_announce(message, priority: :assertive, **options)
  end
  
  # Generate a status update announcement
  def announce_status(message, **options)
    screen_reader_announce(message, priority: :status, **options)
  end
  
  # Create announcement for successful actions
  def announce_success(action, item = nil)
    message = build_success_message(action, item)
    announce_politely(message)
  end
  
  # Create announcement for error conditions
  def announce_error(error_message)
    message = "Error: #{error_message}. Please review and try again."
    announce_urgently(message)
  end
  
  # Create announcement for loading states
  def announce_loading(action = "Loading")
    announce_status("#{action}...")
  end
  
  # Create announcement for completion states
  def announce_complete(action = "Action")
    announce_status("#{action} completed")
  end
  
  # ARIA attributes for form elements
  def aria_form_attributes(field_name, errors: nil, required: false, described_by: nil)
    attrs = {}
    
    if required
      attrs['aria-required'] = 'true'
    end
    
    if errors&.any?
      error_id = "#{field_name}-error"
      attrs['aria-invalid'] = 'true'
      attrs['aria-describedby'] = [described_by, error_id].compact.join(' ')
    elsif described_by
      attrs['aria-describedby'] = described_by
    end
    
    attrs
  end
  
  # Generate error announcement for form fields
  def field_error_announcement(field_name, errors)
    return '' if errors.blank?
    
    error_text = errors.first
    message = "#{field_name.humanize} has an error: #{error_text}"
    announce_urgently(message)
  end
  
  # Generate announcement for dynamic content changes
  def content_change_announcement(change_type, item_type = "content")
    messages = {
      created: "New #{item_type} added",
      updated: "#{item_type.capitalize} updated",
      deleted: "#{item_type.capitalize} removed",
      restored: "#{item_type.capitalize} restored"
    }
    
    message = messages[change_type.to_sym] || "#{item_type.capitalize} changed"
    announce_politely(message)
  end
  
  # Generate announcement for navigation changes
  def navigation_announcement(page_name)
    announce_politely("Navigated to #{page_name}")
  end
  
  # Generate announcement for filter/search operations
  def search_results_announcement(count, search_term = nil)
    if search_term.present?
      message = "Search for '#{search_term}' returned #{pluralize(count, 'result')}"
    else
      message = "Showing #{pluralize(count, 'result')}"
    end
    
    announce_politely(message)
  end
  
  # Generate announcement for pagination changes
  def pagination_announcement(current_page, total_pages)
    message = "Page #{current_page} of #{total_pages}"
    announce_status(message)
  end
  
  # Create accessible button with proper ARIA attributes
  def accessible_button(text, options = {})
    options[:role] ||= 'button'
    options[:tabindex] ||= '0'
    
    if options[:disabled]
      options['aria-disabled'] = 'true'
      options[:tabindex] = '-1'
    end
    
    if options[:expanded].present?
      options['aria-expanded'] = options.delete(:expanded).to_s
    end
    
    if options[:controls]
      options['aria-controls'] = options.delete(:controls)
    end
    
    content_tag :button, text, options
  end
  
  # Create accessible link with proper context
  def accessible_link(text, url, options = {})
    # Add context if link text might be ambiguous
    if options[:context]
      text += content_tag(:span, " (#{options.delete(:context)})", class: 'sr-only')
    end
    
    link_to text, url, options
  end
  
  # Generate loading state announcement with timeout
  def loading_state_announcement(action, timeout: 30)
    content_tag :script, type: 'application/javascript', data: { turbo_temporary: true } do
      <<~JAVASCRIPT.html_safe
        (function() {
          const controller = document.querySelector('[data-controller~="screen-reader"]');
          if (controller) {
            const screenReaderController = controller.screenReaderController || application.getControllerForElementAndIdentifier(controller, 'screen-reader');
            if (screenReaderController) {
              screenReaderController.announceStatus('#{action}...');
              
              // Set timeout for loading announcement
              setTimeout(() => {
                screenReaderController.announceUrgent('#{action} is taking longer than expected. Please wait or try refreshing the page.');
              }, #{timeout * 1000});
            }
          }
        })();
      JAVASCRIPT
    end
  end
  
  private
  
  def javascript_announcement(message, priority, options)
    delay = options[:delay] || 100
    clear = options[:clear] != false
    
    <<~JAVASCRIPT.html_safe
      (function() {
        setTimeout(() => {
          const event = new CustomEvent('screenreader:#{priority == :assertive ? 'urgent' : priority}', {
            detail: { 
              message: #{message.to_json}, 
              options: { 
                priority: #{priority.to_json},
                delay: #{delay},
                clear: #{clear}
              } 
            }
          });
          document.dispatchEvent(event);
        }, 50);
      })();
    JAVASCRIPT
  end
  
  def build_success_message(action, item)
    case action.to_s
    when 'create', 'created'
      item ? "#{item} created successfully" : "Item created successfully"
    when 'update', 'updated'
      item ? "#{item} updated successfully" : "Item updated successfully"  
    when 'delete', 'deleted', 'destroy', 'destroyed'
      item ? "#{item} deleted successfully" : "Item deleted successfully"
    when 'save', 'saved'
      item ? "#{item} saved successfully" : "Changes saved successfully"
    else
      item ? "#{action} #{item} completed successfully" : "#{action} completed successfully"
    end
  end
end