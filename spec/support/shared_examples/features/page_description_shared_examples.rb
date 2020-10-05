# frozen_string_literal: true

RSpec.shared_examples 'page meta description' do |expected_description|
  it 'renders the page with description, og:description, and twitter:description meta tags that contains a plain-text version of the markdown', :aggregate_failures do
    %w(name='description' property='og:description' property='twitter:description').each do |selector|
      expect(page).to have_selector("meta[#{selector}][content='#{expected_description}']", visible: false)
    end
  end
end
