shared_examples 'dirty submit form' do |selector_args|
  selectors = selector_args.is_a?(Array) ? selector_args : [selector_args]

  selectors.each do |selector|
    it "disables #{selector[:form]} submit until there are changes", :js do
      form = find(selector[:form])
      submit = form.first('.js-dirty-submit')
      input = form.first(selector[:input])
      original_value = input.value

      expect(submit.disabled?).to be true

      input.set("#{original_value} changes")

      form.find('.js-dirty-submit:not([disabled])', match: :first)
      expect(submit.disabled?).to be false

      input.set(original_value)

      form.find('.js-dirty-submit[disabled]', match: :first)
      expect(submit.disabled?).to be true
    end
  end
end
