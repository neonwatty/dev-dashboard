# frozen_string_literal: true

# Mobile-responsive form field component
# Provides consistent, touch-friendly form inputs with proper labeling and error handling
class FormFieldComponent < MobileResponsiveComponent
  def initialize(
    label:,
    field_type: :text,
    name: nil,
    id: nil,
    value: nil,
    placeholder: nil,
    required: false,
    help_text: nil,
    error: nil,
    options: [],
    **attributes
  )
    @label = label
    @field_type = field_type
    @name = name
    @id = id || name
    @value = value
    @placeholder = placeholder
    @required = required
    @help_text = help_text
    @error = error
    @options = options
    @attributes = attributes
  end

  private

  attr_reader :label, :field_type, :name, :id, :value, :placeholder, :required, :help_text, :error, :options, :attributes

  def field_wrapper_classes
    mobile_form_classes
  end

  def label_classes
    classes = mobile_label_classes
    classes += " text-red-600 dark:text-red-400" if error.present?
    classes
  end

  def field_classes
    base_classes = [
      "w-full px-3 py-3 border rounded-md",
      "focus:outline-none focus:ring-2 focus:ring-blue-500",
      "dark:bg-gray-700 dark:text-white transition-colors",
      mobile_input_classes
    ].join(" ")

    border_classes = if error.present?
                       "border-red-300 dark:border-red-600 focus:border-red-500"
                     else
                       "border-gray-300 dark:border-gray-600 focus:border-blue-500"
                     end

    "#{base_classes} #{border_classes}"
  end

  def help_text_classes
    mobile_help_text_classes
  end

  def error_classes
    mobile_error_classes
  end

  def required_indicator
    return "" unless required
    '<span class="text-red-500 ml-1">*</span>'.html_safe
  end

  def field_attributes
    base_attrs = {
      class: field_classes,
      id: id,
      name: name,
      required: required
    }.compact

    base_attrs[:placeholder] = placeholder if placeholder.present?
    base_attrs[:value] = value if value.present? && !%i[select checkbox radio].include?(field_type)
    
    base_attrs.merge(attributes)
  end

  def render_text_field
    tag.input(**field_attributes.merge(type: :text))
  end

  def render_email_field
    tag.input(**field_attributes.merge(type: :email))
  end

  def render_password_field
    tag.input(**field_attributes.merge(type: :password))
  end

  def render_number_field
    tag.input(**field_attributes.merge(type: :number))
  end

  def render_date_field
    tag.input(**field_attributes.merge(type: :date))
  end

  def render_textarea
    content_tag(:textarea, value, field_attributes.except(:value))
  end

  def render_select
    content_tag(:select, field_attributes) do
      options.map do |option|
        if option.is_a?(Array)
          option_text, option_value = option
          selected = value == option_value.to_s
          tag.option(option_text, value: option_value, selected: selected)
        else
          selected = value == option.to_s
          tag.option(option, value: option, selected: selected)
        end
      end.join.html_safe
    end
  end

  def render_checkbox
    wrapper_attrs = {
      class: "flex items-center gap-3 #{touch_target_classes}"
    }

    checkbox_attrs = field_attributes.merge(
      type: :checkbox,
      class: "w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 rounded focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600",
      checked: value
    ).except(:placeholder)

    content_tag(:div, wrapper_attrs) do
      [
        tag.input(**checkbox_attrs),
        content_tag(:label, label, for: id, class: "text-sm font-medium text-gray-900 dark:text-gray-300")
      ].join.html_safe
    end
  end

  def render_radio_group
    content_tag(:div, class: "space-y-2") do
      options.map.with_index do |option, index|
        option_text, option_value = option.is_a?(Array) ? option : [option, option]
        option_id = "#{id}_#{index}"
        checked = value == option_value.to_s

        wrapper_attrs = {
          class: "flex items-center gap-3 #{touch_target_classes}"
        }

        radio_attrs = {
          type: :radio,
          id: option_id,
          name: name,
          value: option_value,
          checked: checked,
          class: "w-4 h-4 text-blue-600 bg-gray-100 border-gray-300 focus:ring-blue-500 dark:focus:ring-blue-600 dark:ring-offset-gray-800 focus:ring-2 dark:bg-gray-700 dark:border-gray-600"
        }

        content_tag(:div, wrapper_attrs) do
          [
            tag.input(**radio_attrs),
            content_tag(:label, option_text, for: option_id, class: "text-sm font-medium text-gray-900 dark:text-gray-300")
          ].join.html_safe
        end
      end.join.html_safe
    end
  end

  def render_field
    case field_type
    when :text
      render_text_field
    when :email
      render_email_field
    when :password
      render_password_field
    when :number
      render_number_field
    when :date
      render_date_field
    when :textarea
      render_textarea
    when :select
      render_select
    when :checkbox
      render_checkbox
    when :radio
      render_radio_group
    else
      render_text_field
    end
  end

  def show_label?
    field_type != :checkbox
  end

  def show_help_text?
    help_text.present?
  end

  def show_error?
    error.present?
  end
end