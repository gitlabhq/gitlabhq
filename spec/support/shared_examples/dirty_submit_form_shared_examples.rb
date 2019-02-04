shared_examples 'dirty submit form' do |selector_args|
  selectors = selector_args.is_a?(Array) ? selector_args : [selector_args]

  def expect_disabled_state(form, submit, is_disabled = true)
    disabled_selector = is_disabled == true ? '[disabled]' : ':not([disabled])'

    form.find(".js-dirty-submit#{disabled_selector}", match: :first)

    expect(submit.disabled?).to be is_disabled
  end

  selectors.each do |selector|
    it "disables #{selector[:form]} submit until there are changes on #{selector[:input]}", :js do
      form = find(selector[:form])
      submit = form.first('.js-dirty-submit')
      input = form.first(selector[:input])
      is_radio = input[:type] == 'radio'
      is_checkbox = input[:type] == 'checkbox'
      is_checkable = is_radio || is_checkbox
      original_value = input.value
      original_checkable = form.find("input[name='#{input[:name]}'][checked]") if is_radio
      original_checkable = input if is_checkbox

      expect(submit.disabled?).to be true
      expect(input.checked?).to be false

      is_checkable ? input.click : input.set("#{original_value} changes")

      expect_disabled_state(form, submit, false)

      is_checkable ? original_checkable.click : input.set(original_value)

      expect_disabled_state(form, submit)
    end
  end
end
