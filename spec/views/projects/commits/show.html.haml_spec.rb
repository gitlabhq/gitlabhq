require 'spec_helper'

describe 'projects/commits/show' do
  let(:project) { create(:project, :repository) }
  let(:repository) { project.repository }
  let(:ref) { GpgHelpers::SIGNED_COMMIT_SHA }

  before do
    allow(view).to receive(:can?).and_return(true)
    allow(view).to receive(:namespace_project_signatures_path).and_return("doesn't matter")

    assign(:project, project)
    assign(:repository, repository)
    assign(:commits, repository.commits(ref))
    assign(:ref, ref)
    assign(:limit, 1)
    assign(:id, ref)
  end

  it 'loads GPG status asynchronously' do
    render
    expect(rendered).to have_css('.gpg-status-box.js-loading-gpg-badge')
    expect(rendered).not_to have_css('.gpg-status-box.invalid')
  end
end
