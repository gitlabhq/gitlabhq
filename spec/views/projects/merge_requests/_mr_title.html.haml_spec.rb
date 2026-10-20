# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/merge_requests/_mr_title.html.haml', feature_category: :code_review_workflow do
  describe '.js-mr-title-actions' do
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

    it 'uses a relative data-url so the cached fragment cannot carry a request host' do
      view.request.host = 'attacker.example.com'

      render

      node = Nokogiri::HTML.fragment(rendered).at_css('.js-mr-title-actions')
      dropdown_data = Gitlab::Json::SafeParser.parse(node['data-more-dropdown'])

      expect(dropdown_data['url']).to eq("/#{project.full_path}/-/merge_requests/#{merge_request.iid}")
    end
  end

  describe 'title', :use_clean_rails_memory_store_fragment_caching do
    # rubocop:disable RSpec/FactoryBot/AvoidCreate -- we need real projects to test redaction
    let_it_be(:private_project) { create(:project, :private) }
    let_it_be(:confidential_issue) { create(:issue, :confidential, project: private_project) }
    let_it_be(:public_project) { create(:project, :public) }
    let_it_be(:merge_request) do
      create(:merge_request, source_project: public_project, target_project: public_project,
        title: "Fix #{confidential_issue.to_reference(full: true)} before release")
    end

    let_it_be(:reporter) { create(:user, reporter_of: private_project) }
    let_it_be(:outsider) { create(:user) }
    # rubocop:enable RSpec/FactoryBot/AvoidCreate

    before do
      assign(:project, public_project)
      assign(:merge_request, merge_request)
    end

    def render_title_as(user)
      allow(view).to receive(:current_user).and_return(user)

      Nokogiri::HTML.fragment(render).at_css('h1.title')
    end

    context 'when a user who can read the referenced confidential issue renders first' do
      it 'links the reference for them and redacts it for a user who cannot' do
        reporter_title = render_title_as(reporter)
        expect(reporter_title.at_css('a.gfm-issue')['title']).to eq(confidential_issue.title)

        outsider_title = render_title_as(outsider)
        expect(outsider_title.at_css('a.gfm-issue')).to be_nil
        expect(outsider_title.text.strip).to eq(merge_request.title)
      end
    end

    context 'when a user who cannot read the referenced confidential issue renders first' do
      it 'redacts the reference for them and links it for a user who can' do
        outsider_title = render_title_as(outsider)
        expect(outsider_title.at_css('a.gfm-issue')).to be_nil

        reporter_title = render_title_as(reporter)
        expect(reporter_title.at_css('a.gfm-issue')['title']).to eq(confidential_issue.title)
      end
    end
  end
end
