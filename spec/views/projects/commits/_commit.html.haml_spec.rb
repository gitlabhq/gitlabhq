require 'spec_helper'

describe 'projects/commits/_commit.html.haml' do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:ref) { GpgHelpers::SIGNED_COMMIT_SHA }
  let(:commit) { repository.commit(ref) }

  def render_partial
    render partial: 'projects/commits/commit', locals: {
      load_signature_async: load_signature_async,
      project: project,
      ref: ref,
      commit: commit
    }
  end

  context 'with load_signature_async set to true' do
    let(:load_signature_async) { true }

    it 'displays GPG status loading indicator' do
      render_partial
      expect(rendered).to have_css('.gpg-status-box.js-loading-gpg-badge')
    end
  end

  context 'with load_signature_async set to false' do
    let(:load_signature_async) { false }

    it 'displays GPG status' do
      render_partial
      expect(rendered).to have_css('.gpg-status-box.invalid')
    end
  end
end
