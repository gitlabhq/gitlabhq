# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/merge_requests/creations/new.html.haml', feature_category: :code_review_workflow do
  let_it_be(:target_project) { build_stubbed(:project, :repository) }

  let(:merge_request) { build(:merge_request, source_project: source_project, target_project: target_project) }

  before do
    controller.prepend_view_path('app/views/projects')

    assign(:project, source_project)
    assign(:merge_request, merge_request)
  end

  shared_examples 'has conflicting merge request guard' do
    context 'when there is conflicting merge request' do
      let(:conflicting_mr) do
        build_stubbed(
          :merge_request,
          source_project: source_project,
          target_project: target_project,
          source_branch: merge_request.source_branch,
          target_branch: merge_request.target_branch
        )
      end

      before do
        allow(merge_request).to receive(:existing_mrs_targeting_same_branch).and_return([conflicting_mr])
      end

      it 'shows conflicting merge request alert' do
        render

        expected_conflicting_mr_link = link_to(
          conflicting_mr.to_reference,
          project_merge_request_path(conflicting_mr.target_project, conflicting_mr)
        )

        expect(flash[:alert]).to include(
          "These branches already have an open merge request: #{expected_conflicting_mr_link}"
        )
      end
    end

    context 'when there is no conflicting merge request' do
      it 'does not show conflicting merge request alert' do
        render

        expect(flash[:alert]).to be_nil
      end
    end
  end

  context 'when merge request is created from other project' do
    let_it_be(:source_project) { build_stubbed(:project, :repository) }

    it_behaves_like 'has conflicting merge request guard'
  end

  context 'when merge request is created from the same project' do
    let_it_be(:source_project) { target_project }

    it_behaves_like 'has conflicting merge request guard'
  end
end
