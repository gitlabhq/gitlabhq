# frozen_string_literal: true

RSpec.shared_examples 'page meta description' do |expected_description|
  it 'renders the page with description, og:description, and twitter:description meta tags that contains a plain-text version of the markdown', :aggregate_failures do
    %w[name='description' property='og:description' property='twitter:description'].each do |selector|
      node = find("meta[#{selector}]", visible: false)
      expect(node['content']).to eq(expected_description)
    end
  end
end

RSpec.shared_examples 'default brand title page meta description' do
  include AppearancesHelper

  it 'renders the page with description, og:description, and twitter:description meta tags with the default brand title', :aggregate_failures do
    %w[name='description' property='og:description' property='twitter:description'].each do |selector|
      node = find("meta[#{selector}]", visible: false)
      expect(node['content']).to eq(default_brand_title)
    end
  end
end
