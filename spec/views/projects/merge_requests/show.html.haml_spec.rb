require 'spec_helper'

describe 'projects/merge_requests/show.html.haml' do
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
    assign(:commits_count, 0)

    allow(view).to receive(:can?).and_return(true)
  end

  context 'when the merge request is closed' do
    it 'shows the "Reopen" button' do
      render

      expect(rendered).to have_css('a', visible: true, text: 'Reopen')
      expect(rendered).to have_css('a', visible: false, text: 'Close')
    end

    it 'does not show the "Reopen" button when the source project does not exist' do
      unlink_project.execute
      closed_merge_request.reload

      render

      expect(rendered).to have_css('a', visible: false, text: 'Reopen')
      expect(rendered).to have_css('a', visible: false, text: 'Close')
    end
  end
end
