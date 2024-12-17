# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LegacyGithubImport::PullRequestFormatter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include Import::GiteaHelper

  let_it_be(:project) do
    create(
      :project,
      :repository,
      :with_import_url,
      :in_group,
      :import_user_mapping_enabled,
      import_type: ::Import::SOURCE_GITEA
    )
  end

  let_it_be(:source_user_mapper) do
    Gitlab::Import::SourceUserMapper.new(
      namespace: project.root_ancestor,
      import_type: project.import_type,
      source_hostname: 'https://gitea.com'
    )
  end

  let_it_be(:octocat) { { id: 123456, login: 'octocat', email: 'octocat@example.com' } }
  let_it_be(:import_source_user) do
    create(
      :import_source_user,
      source_user_identifier: octocat[:id],
      namespace: project.root_ancestor,
      source_hostname: 'https://gitea.com',
      import_type: ::Import::SOURCE_GITEA
    )
  end

  let(:client) { instance_double(Gitlab::LegacyGithubImport::Client) }
  let(:ghost_user) { { id: -1, login: 'Ghost' } }
  let(:source_sha) { create(:commit, project: project).id }
  let(:target_commit) { create(:commit, project: project, git_commit: RepoHelpers.another_sample_commit) }
  let(:target_sha) { target_commit.id }
  let(:target_short_sha) { target_commit.id.to_s[0..7] }
  let(:repository) { { id: 1, fork: false } }
  let(:source_repo) { repository }
  let(:source_branch) { { ref: 'branch-merged', repo: source_repo, sha: source_sha } }
  let(:forked_source_repo) { { id: 2, fork: true, name: 'otherproject', full_name: 'company/otherproject' } }
  let(:target_repo) { repository }
  let(:target_branch) { { ref: 'master', repo: target_repo, sha: target_sha, user: octocat } }
  let(:removed_branch) { { ref: 'removed-branch', repo: source_repo, sha: '2e5d3239642f9161dcbbc4b70a211a68e5e45e2b', user: octocat } }
  let(:forked_branch) { { ref: 'master', repo: forked_source_repo, sha: '2e5d3239642f9161dcbbc4b70a211a68e5e45e2b', user: octocat } }
  let(:branch_deleted_repo) { { ref: 'master', repo: nil, sha: '2e5d3239642f9161dcbbc4b70a211a68e5e45e2b', user: octocat } }
  let(:created_at) { DateTime.strptime('2011-01-26T19:01:12Z') }
  let(:updated_at) { DateTime.strptime('2011-01-27T19:01:12Z') }
  let(:imported_from) { ::Import::SOURCE_GITEA }
  let(:base_data) do
    {
      number: 1347,
      milestone: nil,
      state: 'open',
      title: 'New feature',
      body: 'Please pull these awesome changes',
      head: source_branch,
      base: target_branch,
      assignee: nil,
      user: octocat,
      created_at: created_at,
      updated_at: updated_at,
      closed_at: nil,
      merged_at: nil,
      url: 'https://api.github.com/repos/octocat/Hello-World/pulls/1347',
      imported_from: imported_from
    }
  end

  subject(:pull_request) { described_class.new(project, raw_data, client, source_user_mapper) }

  before do
    allow(client).to receive(:user).and_return(octocat)
  end

  shared_examples 'Gitlab::LegacyGithubImport::PullRequestFormatter#attributes' do
    context 'when pull request is open' do
      let(:raw_data) { base_data.merge(state: 'open') }

      it 'returns formatted attributes' do
        expected = {
          iid: 1347,
          title: 'New feature',
          description: "Please pull these awesome changes",
          source_project: project,
          source_branch: 'branch-merged',
          source_branch_sha: source_sha,
          target_project: project,
          target_branch: 'master',
          target_branch_sha: target_sha,
          state: 'opened',
          milestone: nil,
          author_id: import_source_user.placeholder_user_id,
          assignee_id: nil,
          created_at: created_at,
          updated_at: updated_at,
          imported_from: imported_from
        }

        expect(pull_request.attributes).to eq(expected)
      end
    end

    context 'when pull request is closed' do
      let(:raw_data) { base_data.merge(state: 'closed') }

      it 'returns formatted attributes' do
        expected = {
          iid: 1347,
          title: 'New feature',
          description: "Please pull these awesome changes",
          source_project: project,
          source_branch: 'branch-merged',
          source_branch_sha: source_sha,
          target_project: project,
          target_branch: 'master',
          target_branch_sha: target_sha,
          state: 'closed',
          milestone: nil,
          author_id: import_source_user.placeholder_user_id,
          assignee_id: nil,
          created_at: created_at,
          updated_at: updated_at,
          imported_from: imported_from
        }

        expect(pull_request.attributes).to eq(expected)
      end
    end

    context 'when pull request is merged' do
      let(:merged_at) { DateTime.strptime('2011-01-28T13:01:12Z') }
      let(:raw_data) { base_data.merge(state: 'closed', merged_at: merged_at) }

      it 'returns formatted attributes' do
        expected = {
          iid: 1347,
          title: 'New feature',
          description: "Please pull these awesome changes",
          source_project: project,
          source_branch: 'branch-merged',
          source_branch_sha: source_sha,
          target_project: project,
          target_branch: 'master',
          target_branch_sha: target_sha,
          state: 'merged',
          milestone: nil,
          author_id: import_source_user.placeholder_user_id,
          assignee_id: nil,
          created_at: created_at,
          updated_at: updated_at,
          imported_from: imported_from
        }

        expect(pull_request.attributes).to eq(expected)
      end
    end

    context 'when it is assigned to someone' do
      context 'and the assigned user has a placeholder user in gitlab' do
        let(:raw_data) { base_data.merge(assignee: octocat) }

        it 'returns an existing placeholder user id' do
          expect(pull_request.attributes.fetch(:assignee_id)).to eq(import_source_user.placeholder_user_id)
        end
      end

      context 'and the assigned user does not already have a placeholder user' do
        let(:octocat_2) { { id: 999999, login: 'octocat two', email: 'octocat2@example.com' } }
        let(:raw_data) { base_data.merge(assignee: octocat_2) }

        it 'creates and returns a new placeholder user id', :aggregate_failures do
          assignee_id = pull_request.attributes.fetch(:assignee_id)

          expect(User.find(assignee_id).user_type).to eq('placeholder')
          expect(assignee_id).not_to eq(import_source_user.placeholder_user_id)
        end
      end

      context 'and it is assigned to a deleted gitea user' do
        let(:raw_data) { base_data.merge(assignee: ghost_user) }

        it 'returns nil for assignee_id' do
          expect(pull_request.attributes.fetch(:assignee_id)).to be_nil
        end
      end

      context 'and user contribution mapping is disabled' do
        let(:raw_data) { base_data.merge(assignee: octocat) }

        before do
          stub_user_mapping_chain(project, false)
        end

        it 'returns nil as assignee_id when is not a GitLab user' do
          expect(pull_request.attributes.fetch(:assignee_id)).to be_nil
        end

        it 'returns GitLab user id associated with Gitea email as assignee_id' do
          gl_user = create(:user, email: octocat[:email])

          expect(pull_request.attributes.fetch(:assignee_id)).to eq gl_user.id
        end
      end
    end

    context 'when pull request has an author' do
      context 'and the author has a placeholder user in gitlab' do
        let(:raw_data) { base_data.merge(user: octocat) }

        it 'returns an existing placeholder user id' do
          expect(pull_request.attributes.fetch(:author_id)).to eq(import_source_user.placeholder_user_id)
        end
      end

      context 'and the author does not already have a placeholder user' do
        let(:octocat_2) { { id: 999999, login: 'octocat two', email: 'octocat2@example.com' } }
        let(:raw_data) { base_data.merge(user: octocat_2) }

        it 'creates and returns a new placeholder user id', :aggregate_failures do
          author_id = pull_request.attributes.fetch(:author_id)
          expect(User.find(author_id).user_type).to eq('placeholder')
          expect(author_id).not_to eq(import_source_user.placeholder_user_id)
        end
      end

      context 'and the author is a deleted gitea user' do
        let(:raw_data) { base_data.merge(user: ghost_user) }

        it 'returns the project creator id' do
          expect(pull_request.attributes.fetch(:author_id)).to eq(project.creator_id)
        end
      end

      context 'and user contribution mapping is disabled' do
        let(:raw_data) { base_data.merge(user: octocat) }

        before do
          stub_user_mapping_chain(project, false)
        end

        it 'returns project creator_id as author_id when is not a GitLab user' do
          expect(pull_request.attributes.fetch(:author_id)).to eq project.creator_id
        end

        it 'returns GitLab user id associated with Gitea email as author_id' do
          gl_user = create(:user, email: octocat[:email])

          expect(pull_request.attributes.fetch(:author_id)).to eq gl_user.id
        end

        it 'returns description without created at tag line' do
          create(:user, email: octocat[:email])

          expect(pull_request.attributes.fetch(:description)).to eq('Please pull these awesome changes')
        end
      end
    end

    context 'when it has a milestone' do
      let(:milestone) { { id: 42, number: 42 } }
      let(:raw_data) { base_data.merge(milestone: milestone) }

      it 'returns nil when milestone does not exist' do
        expect(pull_request.attributes.fetch(:milestone)).to be_nil
      end

      it 'returns milestone when it exists' do
        milestone = create(:milestone, project: project, iid: 42)

        expect(pull_request.attributes.fetch(:milestone)).to eq milestone
      end
    end
  end

  shared_examples 'Gitlab::LegacyGithubImport::PullRequestFormatter#number' do
    let(:raw_data) { base_data }

    it 'returns pull request number' do
      expect(pull_request.number).to eq 1347
    end
  end

  shared_examples 'Gitlab::LegacyGithubImport::PullRequestFormatter#source_branch_name' do
    context 'when source branch exists' do
      let(:raw_data) { base_data }

      it 'returns branch ref' do
        expect(pull_request.source_branch_name).to eq 'branch-merged'
      end
    end

    context 'when source branch does not exist' do
      let(:raw_data) { base_data.merge(head: removed_branch) }

      it 'prefixes branch name with gh-:short_sha/:number/:user pattern to avoid collision' do
        expect(pull_request.source_branch_name).to eq "gh-#{target_short_sha}/1347/octocat/removed-branch"
      end
    end

    context 'when source branch is from a fork' do
      let(:raw_data) { base_data.merge(head: forked_branch) }

      it 'prefixes branch name with gh-:short_sha/:number/:user pattern to avoid collision' do
        expect(pull_request.source_branch_name).to eq "gh-#{target_short_sha}/1347/octocat/master"
      end
    end

    context 'when source branch is from a deleted fork' do
      let(:raw_data) { base_data.merge(head: branch_deleted_repo) }

      it 'prefixes branch name with gh-:short_sha/:number/:user pattern to avoid collision' do
        expect(pull_request.source_branch_name).to eq "gh-#{target_short_sha}/1347/octocat/master"
      end
    end
  end

  shared_examples 'Gitlab::LegacyGithubImport::PullRequestFormatter#target_branch_name' do
    context 'when target branch exists' do
      let(:raw_data) { base_data }

      it 'returns branch ref' do
        expect(pull_request.target_branch_name).to eq 'master'
      end
    end

    context 'when target branch does not exist' do
      let(:raw_data) { base_data.merge(base: removed_branch) }

      it 'prefixes branch name with gh-:short_sha/:number/:user pattern to avoid collision' do
        expect(pull_request.target_branch_name).to eq 'gl-2e5d3239/1347/octocat/removed-branch'
      end
    end
  end

  context 'when importing a Gitea project' do
    it_behaves_like 'Gitlab::LegacyGithubImport::PullRequestFormatter#attributes'
    it_behaves_like 'Gitlab::LegacyGithubImport::PullRequestFormatter#number'
    it_behaves_like 'Gitlab::LegacyGithubImport::PullRequestFormatter#source_branch_name'
    it_behaves_like 'Gitlab::LegacyGithubImport::PullRequestFormatter#target_branch_name'
  end

  context 'when importing a GitHub project' do
    let_it_be(:project) do
      create(
        :project,
        :repository,
        :with_import_url,
        :in_group,
        :import_user_mapping_enabled,
        import_type: ::Import::SOURCE_GITHUB
      )
    end

    let_it_be(:source_user_mapper) do
      Gitlab::Import::SourceUserMapper.new(
        namespace: project.root_ancestor,
        import_type: project.import_type,
        source_hostname: 'https://github.com'
      )
    end

    let_it_be(:import_source_user) do
      create(
        :import_source_user,
        source_user_identifier: octocat[:id],
        namespace: project.root_ancestor,
        source_hostname: 'https://github.com',
        import_type: ::Import::SOURCE_GITHUB
      )
    end

    let(:imported_from) { ::Import::SOURCE_GITHUB }

    it_behaves_like 'Gitlab::LegacyGithubImport::PullRequestFormatter#attributes'
    it_behaves_like 'Gitlab::LegacyGithubImport::PullRequestFormatter#number'
    it_behaves_like 'Gitlab::LegacyGithubImport::PullRequestFormatter#source_branch_name'
    it_behaves_like 'Gitlab::LegacyGithubImport::PullRequestFormatter#target_branch_name'
  end

  describe '#valid?' do
    context 'when source, and target repos are not a fork' do
      let(:raw_data) { base_data }

      it 'returns true' do
        expect(pull_request.valid?).to eq true
      end
    end

    context 'when source repo is a fork' do
      let(:source_repo) { { id: 2 } }
      let(:raw_data) { base_data }

      it 'returns true' do
        expect(pull_request.valid?).to eq true
      end
    end

    context 'when target repo is a fork' do
      let(:target_repo) { { id: 2 } }
      let(:raw_data) { base_data }

      it 'returns true' do
        expect(pull_request.valid?).to eq true
      end
    end
  end

  describe '#cross_project?' do
    context 'when source and target repositories are different' do
      let(:raw_data) { base_data.merge(head: forked_branch) }

      it 'returns true' do
        expect(pull_request.cross_project?).to eq true
      end
    end

    context 'when source repository does not exist anymore' do
      let(:raw_data) { base_data.merge(head: branch_deleted_repo) }

      it 'returns true' do
        expect(pull_request.cross_project?).to eq true
      end
    end

    context 'when source and target repositories are the same' do
      let(:raw_data) { base_data.merge(head: source_branch) }

      it 'returns false' do
        expect(pull_request.cross_project?).to eq false
      end
    end
  end

  describe '#source_branch_exists?' do
    let(:raw_data) { base_data.merge(head: forked_branch) }

    it 'returns false when is a cross_project' do
      expect(pull_request.source_branch_exists?).to eq false
    end
  end

  describe '#url' do
    let(:raw_data) { base_data }

    it 'return raw url' do
      expect(pull_request.url).to eq 'https://api.github.com/repos/octocat/Hello-World/pulls/1347'
    end
  end

  describe '#opened?' do
    let(:raw_data) { base_data.merge(state: 'open') }

    it 'returns true when state is "open"' do
      expect(pull_request.opened?).to be_truthy
    end
  end

  describe '#project_association' do
    let(:raw_data) { base_data }

    it { expect(pull_request.project_association).to eq(:merge_requests) }
  end

  describe '#project_assignee_association' do
    let(:raw_data) { base_data }

    it { expect(pull_request.project_assignee_association).to eq(:merge_request_assignees) }
  end

  describe '#contributing_user_formatters' do
    let(:raw_data) { base_data }

    it 'returns a hash containing UserFormatters for user references in attributes' do
      expect(pull_request.contributing_user_formatters).to match(
        a_hash_including({ author_id: a_kind_of(Gitlab::LegacyGithubImport::UserFormatter) })
      )
    end

    it 'includes all user reference columns in #attributes' do
      all_user_references = Gitlab::ImportExport::Base::RelationFactory::USER_REFERENCES.map(&:to_sym)

      # assignee_id does not need a reference from the attribute on the MR, it's handled through merge_request_assignees
      expect(pull_request.contributing_user_formatters.keys).to match_array(
        (pull_request.attributes.keys & all_user_references) - [:assignee_id]
      )
    end
  end

  describe '#contributing_assignee_formatters' do
    let(:raw_data) { base_data.merge(assignee: octocat) }

    it 'returns a hash containing the author UserFormatter' do
      expect(pull_request.contributing_assignee_formatters).to match(
        a_hash_including({ user_id: a_kind_of(Gitlab::LegacyGithubImport::UserFormatter) })
      )
    end
  end

  describe '#create!', :aggregate_failures, :clean_gitlab_redis_shared_state do
    let(:raw_data) { base_data.merge(assignee: octocat) }
    let(:store) { project.placeholder_reference_store }

    it 'saves the pull_request and assignees' do
      pull_request.create!
      created_pull_request = project.merge_requests.find_by_iid(pull_request.attributes[:iid])

      expect(created_pull_request).not_to be_nil
      expect(created_pull_request&.merge_request_assignees).not_to be_empty
    end

    it 'pushes placeholder references for user references on the pull_request' do
      pull_request.create!
      cached_references = store.get(100).filter_map do |item|
        reference = Import::SourceUserPlaceholderReference.from_serialized(item)
        reference if reference.model == 'MergeRequest'
      end

      expect(cached_references.map(&:model)).to eq(['MergeRequest'])
      expect(cached_references.map(&:source_user_id)).to eq([import_source_user.id])
      expect(cached_references.map(&:user_reference_column)).to eq(['author_id'])
    end

    it 'pushes placeholder references for user references on the pull_request assignees' do
      pull_request.create!
      cached_references = store.get(100).filter_map do |item|
        reference = Import::SourceUserPlaceholderReference.from_serialized(item)
        reference if reference.model == 'MergeRequestAssignee'
      end

      expect(cached_references.map(&:model)).to match_array(['MergeRequestAssignee'])
      expect(cached_references.map(&:source_user_id).uniq).to eq([import_source_user.id])
      expect(cached_references.map(&:user_reference_column)).to match_array(['user_id'])
    end

    context 'when the pull_request references deleted users in Gitea' do
      let(:raw_data) { base_data.merge(user: ghost_user, assignee: ghost_user) }

      it 'does not push any placeholder references' do
        pull_request.create!
        expect(store.empty?).to eq(true)
      end
    end

    context 'when user contribution mapping is disabled' do
      before do
        stub_user_mapping_chain(project, false)
      end

      it 'does not push any placeholder references' do
        pull_request.create!
        expect(store.empty?).to eq(true)
      end
    end
  end
end
