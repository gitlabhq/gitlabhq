# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LegacyGithubImport::PullRequestFormatter do
  let(:client) { double }
  let(:project) { create(:project, :repository) }
  let(:source_sha) { create(:commit, project: project).id }
  let(:target_commit) { create(:commit, project: project, git_commit: RepoHelpers.another_sample_commit) }
  let(:target_sha) { target_commit.id }
  let(:target_short_sha) { target_commit.id.to_s[0..7] }
  let(:repository) { double(id: 1, fork: false) }
  let(:source_repo) { repository }
  let(:source_branch) { double(ref: 'branch-merged', repo: source_repo, sha: source_sha) }
  let(:forked_source_repo) { double(id: 2, fork: true, name: 'otherproject', full_name: 'company/otherproject') }
  let(:target_repo) { repository }
  let(:target_branch) { double(ref: 'master', repo: target_repo, sha: target_sha, user: octocat) }
  let(:removed_branch) { double(ref: 'removed-branch', repo: source_repo, sha: '2e5d3239642f9161dcbbc4b70a211a68e5e45e2b', user: octocat) }
  let(:forked_branch) { double(ref: 'master', repo: forked_source_repo, sha: '2e5d3239642f9161dcbbc4b70a211a68e5e45e2b', user: octocat) }
  let(:branch_deleted_repo) { double(ref: 'master', repo: nil, sha: '2e5d3239642f9161dcbbc4b70a211a68e5e45e2b', user: octocat) }
  let(:octocat) { double(id: 123456, login: 'octocat', email: 'octocat@example.com') }
  let(:created_at) { DateTime.strptime('2011-01-26T19:01:12Z') }
  let(:updated_at) { DateTime.strptime('2011-01-27T19:01:12Z') }
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
      url: 'https://api.github.com/repos/octocat/Hello-World/pulls/1347'
    }
  end

  subject(:pull_request) { described_class.new(project, raw_data, client) }

  before do
    allow(client).to receive(:user).and_return(octocat)
  end

  shared_examples 'Gitlab::LegacyGithubImport::PullRequestFormatter#attributes' do
    context 'when pull request is open' do
      let(:raw_data) { double(base_data.merge(state: 'open')) }

      it 'returns formatted attributes' do
        expected = {
          iid: 1347,
          title: 'New feature',
          description: "*Created by: octocat*\n\nPlease pull these awesome changes",
          source_project: project,
          source_branch: 'branch-merged',
          source_branch_sha: source_sha,
          target_project: project,
          target_branch: 'master',
          target_branch_sha: target_sha,
          state: 'opened',
          milestone: nil,
          author_id: project.creator_id,
          assignee_id: nil,
          created_at: created_at,
          updated_at: updated_at,
          imported: true
        }

        expect(pull_request.attributes).to eq(expected)
      end
    end

    context 'when pull request is closed' do
      let(:raw_data) { double(base_data.merge(state: 'closed')) }

      it 'returns formatted attributes' do
        expected = {
          iid: 1347,
          title: 'New feature',
          description: "*Created by: octocat*\n\nPlease pull these awesome changes",
          source_project: project,
          source_branch: 'branch-merged',
          source_branch_sha: source_sha,
          target_project: project,
          target_branch: 'master',
          target_branch_sha: target_sha,
          state: 'closed',
          milestone: nil,
          author_id: project.creator_id,
          assignee_id: nil,
          created_at: created_at,
          updated_at: updated_at,
          imported: true
        }

        expect(pull_request.attributes).to eq(expected)
      end
    end

    context 'when pull request is merged' do
      let(:merged_at) { DateTime.strptime('2011-01-28T13:01:12Z') }
      let(:raw_data) { double(base_data.merge(state: 'closed', merged_at: merged_at)) }

      it 'returns formatted attributes' do
        expected = {
          iid: 1347,
          title: 'New feature',
          description: "*Created by: octocat*\n\nPlease pull these awesome changes",
          source_project: project,
          source_branch: 'branch-merged',
          source_branch_sha: source_sha,
          target_project: project,
          target_branch: 'master',
          target_branch_sha: target_sha,
          state: 'merged',
          milestone: nil,
          author_id: project.creator_id,
          assignee_id: nil,
          created_at: created_at,
          updated_at: updated_at,
          imported: true
        }

        expect(pull_request.attributes).to eq(expected)
      end
    end

    context 'when it is assigned to someone' do
      let(:raw_data) { double(base_data.merge(assignee: octocat)) }

      it 'returns nil as assignee_id when is not a GitLab user' do
        expect(pull_request.attributes.fetch(:assignee_id)).to be_nil
      end

      it 'returns GitLab user id associated with GitHub id as assignee_id' do
        gl_user = create(:omniauth_user, extern_uid: octocat.id, provider: 'github')

        expect(pull_request.attributes.fetch(:assignee_id)).to eq gl_user.id
      end

      it 'returns GitLab user id associated with GitHub email as assignee_id' do
        gl_user = create(:user, email: octocat.email)

        expect(pull_request.attributes.fetch(:assignee_id)).to eq gl_user.id
      end
    end

    context 'when author is a GitLab user' do
      let(:raw_data) { double(base_data.merge(user: octocat)) }

      it 'returns project creator_id as author_id when is not a GitLab user' do
        expect(pull_request.attributes.fetch(:author_id)).to eq project.creator_id
      end

      it 'returns GitLab user id associated with GitHub id as author_id' do
        gl_user = create(:omniauth_user, extern_uid: octocat.id, provider: 'github')

        expect(pull_request.attributes.fetch(:author_id)).to eq gl_user.id
      end

      it 'returns GitLab user id associated with GitHub email as author_id' do
        gl_user = create(:user, email: octocat.email)

        expect(pull_request.attributes.fetch(:author_id)).to eq gl_user.id
      end

      it 'returns description without created at tag line' do
        create(:omniauth_user, extern_uid: octocat.id, provider: 'github')

        expect(pull_request.attributes.fetch(:description)).to eq('Please pull these awesome changes')
      end
    end

    context 'when it has a milestone' do
      let(:milestone) { double(id: 42, number: 42) }
      let(:raw_data) { double(base_data.merge(milestone: milestone)) }

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
    let(:raw_data) { double(base_data) }

    it 'returns pull request number' do
      expect(pull_request.number).to eq 1347
    end
  end

  shared_examples 'Gitlab::LegacyGithubImport::PullRequestFormatter#source_branch_name' do
    context 'when source branch exists' do
      let(:raw_data) { double(base_data) }

      it 'returns branch ref' do
        expect(pull_request.source_branch_name).to eq 'branch-merged'
      end
    end

    context 'when source branch does not exist' do
      let(:raw_data) { double(base_data.merge(head: removed_branch)) }

      it 'prefixes branch name with gh-:short_sha/:number/:user pattern to avoid collision' do
        expect(pull_request.source_branch_name).to eq "gh-#{target_short_sha}/1347/octocat/removed-branch"
      end
    end

    context 'when source branch is from a fork' do
      let(:raw_data) { double(base_data.merge(head: forked_branch)) }

      it 'prefixes branch name with gh-:short_sha/:number/:user pattern to avoid collision' do
        expect(pull_request.source_branch_name).to eq "gh-#{target_short_sha}/1347/octocat/master"
      end
    end

    context 'when source branch is from a deleted fork' do
      let(:raw_data) { double(base_data.merge(head: branch_deleted_repo)) }

      it 'prefixes branch name with gh-:short_sha/:number/:user pattern to avoid collision' do
        expect(pull_request.source_branch_name).to eq "gh-#{target_short_sha}/1347/octocat/master"
      end
    end
  end

  shared_examples 'Gitlab::LegacyGithubImport::PullRequestFormatter#target_branch_name' do
    context 'when target branch exists' do
      let(:raw_data) { double(base_data) }

      it 'returns branch ref' do
        expect(pull_request.target_branch_name).to eq 'master'
      end
    end

    context 'when target branch does not exist' do
      let(:raw_data) { double(base_data.merge(base: removed_branch)) }

      it 'prefixes branch name with gh-:short_sha/:number/:user pattern to avoid collision' do
        expect(pull_request.target_branch_name).to eq 'gl-2e5d3239/1347/octocat/removed-branch'
      end
    end
  end

  context 'when importing a GitHub project' do
    it_behaves_like 'Gitlab::LegacyGithubImport::PullRequestFormatter#attributes'
    it_behaves_like 'Gitlab::LegacyGithubImport::PullRequestFormatter#number'
    it_behaves_like 'Gitlab::LegacyGithubImport::PullRequestFormatter#source_branch_name'
    it_behaves_like 'Gitlab::LegacyGithubImport::PullRequestFormatter#target_branch_name'
  end

  context 'when importing a Gitea project' do
    before do
      project.update!(import_type: 'gitea')
    end

    it_behaves_like 'Gitlab::LegacyGithubImport::PullRequestFormatter#attributes'
    it_behaves_like 'Gitlab::LegacyGithubImport::PullRequestFormatter#number'
    it_behaves_like 'Gitlab::LegacyGithubImport::PullRequestFormatter#source_branch_name'
    it_behaves_like 'Gitlab::LegacyGithubImport::PullRequestFormatter#target_branch_name'
  end

  describe '#valid?' do
    context 'when source, and target repos are not a fork' do
      let(:raw_data) { double(base_data) }

      it 'returns true' do
        expect(pull_request.valid?).to eq true
      end
    end

    context 'when source repo is a fork' do
      let(:source_repo) { double(id: 2) }
      let(:raw_data) { double(base_data) }

      it 'returns true' do
        expect(pull_request.valid?).to eq true
      end
    end

    context 'when target repo is a fork' do
      let(:target_repo) { double(id: 2) }
      let(:raw_data) { double(base_data) }

      it 'returns true' do
        expect(pull_request.valid?).to eq true
      end
    end
  end

  describe '#cross_project?' do
    context 'when source and target repositories are different' do
      let(:raw_data) { double(base_data.merge(head: forked_branch)) }

      it 'returns true' do
        expect(pull_request.cross_project?).to eq true
      end
    end

    context 'when source repository does not exist anymore' do
      let(:raw_data) { double(base_data.merge(head: branch_deleted_repo)) }

      it 'returns true' do
        expect(pull_request.cross_project?).to eq true
      end
    end

    context 'when source and target repositories are the same' do
      let(:raw_data) { double(base_data.merge(head: source_branch)) }

      it 'returns false' do
        expect(pull_request.cross_project?).to eq false
      end
    end
  end

  describe '#source_branch_exists?' do
    let(:raw_data) { double(base_data.merge(head: forked_branch)) }

    it 'returns false when is a cross_project' do
      expect(pull_request.source_branch_exists?).to eq false
    end
  end

  describe '#url' do
    let(:raw_data) { double(base_data) }

    it 'return raw url' do
      expect(pull_request.url).to eq 'https://api.github.com/repos/octocat/Hello-World/pulls/1347'
    end
  end

  describe '#opened?' do
    let(:raw_data) { double(base_data.merge(state: 'open')) }

    it 'returns true when state is "open"' do
      expect(pull_request.opened?).to be_truthy
    end
  end
end
