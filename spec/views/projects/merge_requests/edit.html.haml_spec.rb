require 'spec_helper'

describe 'projects/merge_requests/edit.html.haml' do
  include Devise::TestHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:fork_project) { create(:project, forked_from_project: project) }
  let(:closed_merge_request) do
    create(:closed_merge_request,
      source_project: fork_project,
      target_project: project,
      author: user)
  end
  let(:unlink_project) { Projects::UnlinkForkService.new(fork_project, user) }

  before do
    assign(:project, project)
    assign(:merge_request, closed_merge_request)

    allow(view).to receive(:can?).and_return(true)
    allow(view).to receive(:current_user).and_return(User.find(closed_merge_request.author_id))
  end

  context 'when closed MR without fork' do
    it "shows editable fields" do
      unlink_project.execute
      closed_merge_request.reload
      render

      expect(rendered).to have_field('merge_request[title]')
      expect(rendered).to have_css('label', text: "Title")
      expect(rendered).to have_field('merge_request[description]')
      expect(rendered).to have_css('label', text: "Description")
      expect(rendered).to have_css('label', text: "Assignee")
      expect(rendered).to have_css('label', text: "Milestone")
      expect(rendered).to have_css('label', text: "Labels")
      expect(rendered).not_to have_css('label', text: "Target branch")
    end
  end
end
