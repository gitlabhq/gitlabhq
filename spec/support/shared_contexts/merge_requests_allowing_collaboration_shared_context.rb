# frozen_string_literal: true

RSpec.shared_context 'merge request allowing collaboration' do
  include ProjectForksHelper

  let(:canonical) { create(:project, :public, :repository) }
  let(:forked_project) { fork_project(canonical, nil, repository: true) }

  before do
    canonical.add_maintainer(user)
    create(
      :merge_request,
      target_project: canonical,
      source_project: forked_project,
      source_branch: 'feature',
      allow_collaboration: true
    )
  end
end
