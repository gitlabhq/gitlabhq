# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/merge_requests/_page.html.haml', feature_category: :code_review_workflow do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:project) { build_stubbed(:project) }
  let_it_be(:merge_request) do
    build_stubbed(:merge_request, source_project: project, target_project: project)
  end

  let_it_be(:issuable_sidebar) do
    MergeRequestSerializer
      .new(current_user: user, project: project)
      .represent(merge_request, serializer: 'sidebar')
  end

  before do
    assign(:issuable_sidebar, issuable_sidebar)
    assign(:project, project)
    assign(:merge_request, merge_request)
    assign(:noteable, merge_request)

    allow(view).to receive(:rapid_diffs_page_enabled?)
    allow(view).to receive(:sticky_header_data)

    stub_template 'projects/merge_requests/_mr_title.html.haml' => ''
    stub_template 'projects/merge_requests/_mr_box.html.haml' => ''
  end

  describe '#js-vue-mr-discussions' do
    it 'renders' do
      render

      expect(rendered).to have_selector('#js-vue-mr-discussions')
    end

    [true, false].each do |archived_status|
      context "when archived is #{archived_status}" do
        before do
          allow(project).to receive(:self_or_ancestors_archived?).and_return(archived_status)

          render
        end

        specify { expect(rendered).to have_selector("#js-vue-mr-discussions[data-archived=\"#{archived_status}\"]") }
      end
    end
  end
end
