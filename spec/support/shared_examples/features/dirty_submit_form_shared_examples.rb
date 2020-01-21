# frozen_string_literal: true

RSpec.shared_examples 'dirty submit form' do |selector_args|
  selectors = selector_args.is_a?(Array) ? selector_args : [selector_args]

  def expect_disabled_state(form, submit_selector, is_disabled = true)
    disabled_selector = is_disabled == true ? '[disabled]' : ':not([disabled])'

    form.find("#{submit_selector}#{disabled_selector}")
  end

  selectors.each do |selector|
    it "disables #{selector[:form]} submit until there are changes on #{selector[:input]}", :js do
      form = find(selector[:form])
      submit_selector = selector[:submit] || 'input[type="submit"]'
      submit = form.first(submit_selector)
      input = form.first(selector[:input])
      is_radio = input[:type] == 'radio'
      is_checkbox = input[:type] == 'checkbox'
      is_checkable = is_radio || is_checkbox
      original_value = input.value
      original_checkable = form.find("input[name='#{input[:name]}'][checked]") if is_radio
      original_checkable = input if is_checkbox

      expect(submit.disabled?).to be true

      is_checkable ? input.click : input.set("#{original_value} changes")

      expect_disabled_state(form, submit_selector, false)

      is_checkable ? original_checkable.click : input.set(original_value)

      expect_disabled_state(form, submit_selector)
    end
  end
end
