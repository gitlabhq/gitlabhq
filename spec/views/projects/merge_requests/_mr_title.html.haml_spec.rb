# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/merge_requests/_mr_title.html.haml', feature_category: :code_review_workflow do
  let(:user) { build_stubbed(:user) }
  let(:project) { build_stubbed(:project) }
  let(:merge_request) do
    build_stubbed(:merge_request, source_project: project, target_project: project)
  end

  before do
    assign(:project, project)
    assign(:merge_request, merge_request)

    allow(view).to receive_messages(current_user: user, markdown_field: merge_request.title)
  end

  describe '.js-mr-title-actions' do
    it 'uses a relative data-url so the cached fragment cannot carry a request host' do
      view.request.host = 'attacker.example.com'

      render

      node = Nokogiri::HTML.fragment(rendered).at_css('.js-mr-title-actions')
      dropdown_data = Gitlab::Json::SafeParser.parse(node['data-more-dropdown'])

      expect(dropdown_data['url']).to eq("/#{project.full_path}/-/merge_requests/#{merge_request.iid}")
    end

    context 'when Ona is enabled for the instance and the user' do
      before do
        stub_application_setting(gitpod_enabled: true, gitpod_url: 'https://ona.example.com')
        allow(user).to receive(:gitpod_enabled).and_return(true)
      end

      it 'builds the Ona path from the configured host, not the request host' do
        view.request.host = 'attacker.example.com'

        render

        node = Nokogiri::HTML.fragment(rendered).at_css('.js-mr-title-actions')
        dropdown_data = Gitlab::Json::SafeParser.parse(node['data-code-dropdown'])

        expect(dropdown_data['gitpod_path']).to eq("https://ona.example.com##{Gitlab::UrlBuilder.build(merge_request)}")
      end
    end
  end
end
