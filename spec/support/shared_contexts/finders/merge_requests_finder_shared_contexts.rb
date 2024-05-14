# frozen_string_literal: true

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

  let_it_be(:user)  { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project1, reload: true) do
    allow_gitaly_n_plus_1 { create(:project, :public, group: group, maintainers: user) }
  end
  # We cannot use `let_it_be` here otherwise we get:
  #   Failure/Error: allow(RepositoryForkWorker).to receive(:perform_async).and_return(true)
  #   The use of doubles or partial doubles from rspec-mocks outside of the per-test lifecycle is not supported.

  let!(:project2) do
    allow_gitaly_n_plus_1 do
      fork_project(project1, user)
    end
  end

  let!(:project3) do
    allow_gitaly_n_plus_1 do
      fork_project(project1, user).tap do |project|
        project.update!(archived: true)
      end
    end
  end

  let_it_be(:project4, reload: true) do
    allow_gitaly_n_plus_1 { create(:project, :repository, group: subgroup, developers: user) }
  end

  let_it_be(:project5, reload: true) do
    allow_gitaly_n_plus_1 { create(:project, group: subgroup, developers: user) }
  end

  let_it_be(:project6, reload: true) do
    allow_gitaly_n_plus_1 { create(:project, group: subgroup, developers: user) }
  end

  let_it_be(:label) { create(:label, project: project1) }
  let_it_be(:label2) { create(:label, project: project1) }

  let!(:merge_request1) do
    create(
      :merge_request, assignees: [user], author: user, reviewers: [user2],
      source_project: project2, target_project: project1,
      target_branch: 'merged-target'
    )
  end

  let!(:merge_request2) do
    create(
      :merge_request, :conflict, assignees: [user], author: user, reviewers: [user2],
      source_project: project2, target_project: project1,
      state: 'closed'
    )
  end

  let!(:merge_request3) do
    create(
      :merge_request, :simple, author: user, assignees: [user2], reviewers: [user],
      source_project: project2, target_project: project2,
      state: 'locked',
      title: 'thing Draft thing'
    )
  end

  let!(:merge_request4) do
    create(
      :merge_request, :simple, author: user,
      source_project: project3, target_project: project3,
      title: 'Draft - thing'
    )
  end

  let_it_be(:merge_request5) do
    create(
      :merge_request, :simple, author: user,
      source_project: project4, target_project: project4,
      title: '[Draft]'
    )
  end

  let!(:label_link) { create(:label_link, label: label, target: merge_request2) }
  let!(:label_link2) { create(:label_link, label: label2, target: merge_request3) }

  before do
    project2.add_developer(user)
    project3.add_developer(user)

    project2.add_developer(user2)
  end
end
