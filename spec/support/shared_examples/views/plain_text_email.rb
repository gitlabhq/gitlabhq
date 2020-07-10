# frozen_string_literal: true

RSpec.shared_examples 'renders plain text email correctly' do
  it 'renders the email without HTML links' do
    render

    expect(rendered).to have_no_selector('a')
  end
end
