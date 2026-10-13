# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/merge_requests/edit.html.haml', feature_category: :code_review_workflow do
  include Devise::Test::ControllerHelpers
  include ProjectForksHelper

  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :repository, developers: user) }
  let_it_be_with_reload(:milestone) { create(:milestone, project: project) }
  let_it_be_with_reload(:forked_project) { fork_project(project, user, repository: true) }

  let_it_be_with_reload(:closed_merge_request) do
    create(:closed_merge_request,
      source_project: forked_project,
      target_project: project,
      author: user,
      assignees: [user],
      reviewers: [user],
      milestone: milestone)
  end

  let(:unlink_project) { Projects::UnlinkForkService.new(forked_project, user) }

  before do
    assign(:project, project)
    assign(:target_project, project)
    assign(:merge_request, closed_merge_request)
    assign(:mr_presenter, closed_merge_request.present(current_user: user))

    allow(view).to receive_messages(can?: true, current_user: User.find(closed_merge_request.author_id))
  end

  shared_examples 'merge request shows editable fields' do
    it 'shows editable fields' do
      render

      expect(rendered).to have_field('merge_request[title]')
      expect(rendered).to have_selector('input[name="merge_request[description]"]', visible: :hidden)
      expect(rendered).to have_selector('.js-milestone-dropdown-root')
      expect(rendered).to have_selector('#merge_request_target_branch', visible: :hidden)
    end
  end

  context 'when a merge request without fork' do
    it_behaves_like 'merge request shows editable fields'

    it "shows editable fields" do
      unlink_project.execute
      closed_merge_request.reload

      render

      expect(rendered).not_to have_selector('#merge_request_target_branch', visible: :hidden)
      expect(rendered).to have_selector('.js-issuable-form-label-selector')
    end
  end

  context 'when a merge request with an existing source project is closed' do
    it_behaves_like 'merge request shows editable fields'

    it "shows editable fields" do
      render

      expect(rendered).to have_selector('#merge_request_target_branch', visible: :hidden)
      expect(rendered).to have_selector('.js-issuable-form-label-selector')
    end
  end
end
