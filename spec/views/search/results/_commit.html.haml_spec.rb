require 'spec_helper'

describe 'search/results/_commit.html.haml' do
  context 'with a signed commit' do
    let(:project) { create(:project, :repository) }
    let(:repository) { project.repository }
    let(:ref) { GpgHelpers::SIGNED_COMMIT_SHA }
    let(:commit) { repository.commit(ref) }

    before do
      assign(:project, project)
    end

    it 'displays GPG status' do
      render partial: 'search/results/commit', locals: { commit: commit }
      expect(rendered).to have_css('.gpg-status-box.invalid')
    end
  end
end
