# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/branches/_commit', feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- requires a real repository to access commits
  let(:commit) { project.repository.commit } # changed from let_it_be to let

  before do
    render partial: 'projects/branches/commit', locals: { commit: commit, project: project }
  end

  it 'renders a link to the commit' do
    expect(rendered).to have_link(commit.short_id, href: project_commit_path(project, commit.id))
  end

  it 'renders with the correct data attributes for the commit popover' do
    expect(rendered).to have_css(
      "a[data-reference-type='commit'][data-commit='#{commit.id}'][data-project-path='#{project.full_path}']"
    )
  end
end
