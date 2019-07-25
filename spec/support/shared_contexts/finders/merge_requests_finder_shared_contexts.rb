# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_context 'MergeRequestsFinder multiple projects with merge requests context' do
  include ProjectForksHelper

  # We need to explicitly permit Gitaly N+1s because of the specs that use
  # :request_store. Gitaly N+1 detection is only enabled when :request_store is,
  # but we don't care about potential N+1s when we're just creating several
  # projects in the setup phase.
  def allow_gitaly_n_plus_1
    Gitlab::GitalyClient.allow_n_plus_1_calls do
      yield
    end
  end

  set(:user)  { create(:user) }
  set(:user2) { create(:user) }

  set(:group) { create(:group) }
  set(:subgroup) { create(:group, parent: group) }
  set(:project1) do
    allow_gitaly_n_plus_1 { create(:project, :public, group: group) }
  end
  # We cannot use `set` here otherwise we get:
  #   Failure/Error: allow(RepositoryForkWorker).to receive(:perform_async).and_return(true)
  #   The use of doubles or partial doubles from rspec-mocks outside of the per-test lifecycle is not supported.
  let(:project2) do
    allow_gitaly_n_plus_1 do
      fork_project(project1, user)
    end
  end
  let(:project3) do
    allow_gitaly_n_plus_1 do
      fork_project(project1, user).tap do |project|
        project.update!(archived: true)
      end
    end
  end
  set(:project4) do
    allow_gitaly_n_plus_1 { create(:project, :repository, group: subgroup) }
  end
  set(:project5) do
    allow_gitaly_n_plus_1 { create(:project, group: subgroup) }
  end
  set(:project6) do
    allow_gitaly_n_plus_1 { create(:project, group: subgroup) }
  end

  let!(:merge_request1) { create(:merge_request, assignees: [user], author: user, source_project: project2, target_project: project1, target_branch: 'merged-target') }
  let!(:merge_request2) { create(:merge_request, :conflict, assignees: [user], author: user, source_project: project2, target_project: project1, state: 'closed') }
  let!(:merge_request3) { create(:merge_request, :simple, author: user, assignees: [user2], source_project: project2, target_project: project2, state: 'locked', title: 'thing WIP thing') }
  let!(:merge_request4) { create(:merge_request, :simple, author: user, source_project: project3, target_project: project3, title: 'WIP thing') }
  let!(:merge_request5) { create(:merge_request, :simple, author: user, source_project: project4, target_project: project4, title: '[WIP]') }

  before do
    project1.add_maintainer(user)
    project2.add_developer(user)
    project3.add_developer(user)
    project4.add_developer(user)
    project5.add_developer(user)
    project6.add_developer(user)

    project2.add_developer(user2)
  end
end
