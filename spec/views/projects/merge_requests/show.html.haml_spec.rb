require 'spec_helper'

describe 'projects/merge_requests/show.html.haml' do
  include Devise::TestHelpers

  let(:project) { create(:project) }
  let(:fork_project) { create(:project, forked_from_project: project) }

  let(:closed_merge_request) do
    create(:closed_merge_request,
      source_project: fork_project,
      source_branch: 'add-submodule-version-bump',
      target_branch: 'master',
      target_project: project)
  end

  before do
    assign(:project, project)
    assign(:merge_request, closed_merge_request)
    assign(:commits_count, 0)

    allow(view).to receive(:can?).and_return(true)
  end

  context 'when merge request is closed' do
    it 'shows Reopen button' do
      render

      expect(rendered).to have_css('a', visible: true, text: 'Reopen')
      expect(rendered).to have_css('a', visible: false, text: 'Close')
    end

    it 'does not show Reopen button without fork' do
      fork_project.destroy
      render

      expect(rendered).to have_css('a', visible: false, text: 'Reopen')
      expect(rendered).to have_css('a', visible: false, text: 'Close')
    end
  end
end
