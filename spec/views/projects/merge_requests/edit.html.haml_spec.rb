require 'spec_helper'

describe 'projects/merge_requests/edit.html.haml' do
  include Devise::TestHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:fork_project) { create(:project, forked_from_project: project) }
  let(:unlink_project) { Projects::UnlinkForkService.new(fork_project, user) }

  let(:closed_merge_request) do
    create(:closed_merge_request,
      source_project: fork_project,
      target_project: project,
      author: user)
  end

  before do
    assign(:project, project)
    assign(:merge_request, closed_merge_request)

    allow(view).to receive(:can?).and_return(true)
    allow(view).to receive(:current_user)
      .and_return(User.find(closed_merge_request.author_id))
  end

  context 'when a merge request without fork' do
    it "shows editable fields" do
      unlink_project.execute
      closed_merge_request.reload

      render

      expect(rendered).to have_field('merge_request[title]')
      expect(rendered).to have_field('merge_request[description]')
      expect(rendered).to have_selector('#merge_request_assignee_id', visible: false)
      expect(rendered).to have_selector('#merge_request_milestone_id', visible: false)
      expect(rendered).not_to have_selector('#merge_request_target_branch', visible: false)
    end
  end

  context 'when a merge request with an existing source project is closed' do
    it "shows editable fields" do
      render

      expect(rendered).to have_field('merge_request[title]')
      expect(rendered).to have_field('merge_request[description]')
      expect(rendered).to have_selector('#merge_request_assignee_id', visible: false)
      expect(rendered).to have_selector('#merge_request_milestone_id', visible: false)
      expect(rendered).to have_selector('#merge_request_target_branch', visible: false)
    end
  end
end
