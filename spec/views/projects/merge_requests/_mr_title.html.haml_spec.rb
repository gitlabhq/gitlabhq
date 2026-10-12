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

  describe '.js-mr-more-dropdown' do
    it 'uses a relative data-url so the cached fragment cannot carry a request host' do
      view.request.host = 'attacker.example.com'

      render

      expect(rendered).to have_selector(
        ".js-mr-more-dropdown[data-url='/#{project.full_path}/-/merge_requests/#{merge_request.iid}']"
      )
    end
  end
end
