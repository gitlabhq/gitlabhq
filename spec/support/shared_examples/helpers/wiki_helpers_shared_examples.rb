# frozen_string_literal: true

RSpec.shared_examples 'wiki endpoint helpers' do
  let(:resource_path) { page.wiki.container.class.to_s.pluralize.downcase }
  let(:url) { "/api/v4/#{resource_path}/#{page.wiki.container.id}/wikis/#{page.slug}?version=#{page.version.id}" }

  it 'returns the full endpoint url' do
    expect(helper.wiki_page_render_api_endpoint(page)).to end_with(url)
  end

  context 'when relative url is set' do
    let(:relative_url) { "/gitlab#{url}" }

    it 'returns the full endpoint url with the relative path' do
      stub_config_setting(relative_url_root: '/gitlab')

      expect(helper.wiki_page_render_api_endpoint(page)).to end_with(relative_url)
    end
  end
end
