# frozen_string_literal: true

RSpec.shared_context 'when a project repository contains a forked commit' do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:repository) { project.repository }
  let_it_be(:forked_project) { fork_project(project, project.owner, repository: true) }

  let_it_be(:forked_commit_sha) do
    forked_project.repository.create_file(project.owner, 'file.txt', 'file', message: 'test', branch_name: 'master')
  end

  before_all do
    # Creating this MR moves the forked commit to the project repository
    create(:merge_request, source_project: forked_project, target_project: project)
  end

  def mock_branch_contains_forked_commit_sha
    allow(repository).to receive(:branch_names_contains).with(forked_commit_sha, limit: 1).and_return(['branch1'])
  end
end
