# frozen_string_literal: true

RSpec.shared_examples 'it renders help text' do
  it 'renders help text' do
    expect(rendered_component).to have_selector('[data-testid="pajamas-component-help-text"]', text: help_text)
  end
end

RSpec.shared_examples 'it does not render help text' do
  it 'does not render help text' do
    expect(rendered_component).not_to have_selector('[data-testid="pajamas-component-help-text"]')
  end
end
