require 'spec_helper'

describe Gitlab::GithubImport::PullRequestFormatter, lib: true do
  let(:project) { create(:project) }
  let(:source_sha) { create(:commit, project: project).id }
  let(:target_sha) { create(:commit, project: project, git_commit: RepoHelpers.another_sample_commit).id }
  let(:repository) { double(id: 1, fork: false) }
  let(:source_repo) { repository }
  let(:source_branch) { double(ref: 'feature', repo: source_repo, sha: source_sha) }
  let(:target_repo) { repository }
  let(:target_branch) { double(ref: 'master', repo: target_repo, sha: target_sha) }
  let(:removed_branch) { double(ref: 'removed-branch', repo: source_repo, sha: '2e5d3239642f9161dcbbc4b70a211a68e5e45e2b') }
  let(:octocat) { double(id: 123456, login: 'octocat') }
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

  subject(:pull_request) { described_class.new(project, raw_data)}

  describe '#attributes' do
    context 'when pull request is open' do
      let(:raw_data) { double(base_data.merge(state: 'open')) }

      it 'returns formatted attributes' do
        expected = {
          iid: 1347,
          title: 'New feature',
          description: "*Created by: octocat*\n\nPlease pull these awesome changes",
          source_project: project,
          source_branch: 'feature',
          source_branch_sha: source_sha,
          target_project: project,
          target_branch: 'master',
          target_branch_sha: target_sha,
          state: 'opened',
          milestone: nil,
          author_id: project.creator_id,
          assignee_id: nil,
          created_at: created_at,
          updated_at: updated_at
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
          source_branch: 'feature',
          source_branch_sha: source_sha,
          target_project: project,
          target_branch: 'master',
          target_branch_sha: target_sha,
          state: 'closed',
          milestone: nil,
          author_id: project.creator_id,
          assignee_id: nil,
          created_at: created_at,
          updated_at: updated_at
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
          source_branch: 'feature',
          source_branch_sha: source_sha,
          target_project: project,
          target_branch: 'master',
          target_branch_sha: target_sha,
          state: 'merged',
          milestone: nil,
          author_id: project.creator_id,
          assignee_id: nil,
          created_at: created_at,
          updated_at: updated_at
        }

        expect(pull_request.attributes).to eq(expected)
      end
    end

    context 'when it is assigned to someone' do
      let(:raw_data) { double(base_data.merge(assignee: octocat)) }

      it 'returns nil as assignee_id when is not a GitLab user' do
        expect(pull_request.attributes.fetch(:assignee_id)).to be_nil
      end

      it 'returns GitLab user id as assignee_id when is a GitLab user' do
        gl_user = create(:omniauth_user, extern_uid: octocat.id, provider: 'github')

        expect(pull_request.attributes.fetch(:assignee_id)).to eq gl_user.id
      end
    end

    context 'when author is a GitLab user' do
      let(:raw_data) { double(base_data.merge(user: octocat)) }

      it 'returns project#creator_id as author_id when is not a GitLab user' do
        expect(pull_request.attributes.fetch(:author_id)).to eq project.creator_id
      end

      it 'returns GitLab user id as author_id when is a GitLab user' do
        gl_user = create(:omniauth_user, extern_uid: octocat.id, provider: 'github')

        expect(pull_request.attributes.fetch(:author_id)).to eq gl_user.id
      end
    end

    context 'when it has a milestone' do
      let(:milestone) { double(number: 45) }
      let(:raw_data) { double(base_data.merge(milestone: milestone)) }

      it 'returns nil when milestone does not exist' do
        expect(pull_request.attributes.fetch(:milestone)).to be_nil
      end

      it 'returns milestone when it exists' do
        milestone = create(:milestone, project: project, iid: 45)

        expect(pull_request.attributes.fetch(:milestone)).to eq milestone
      end
    end
  end

  describe '#number' do
    let(:raw_data) { double(base_data.merge(number: 1347)) }

    it 'returns pull request number' do
      expect(pull_request.number).to eq 1347
    end
  end

  describe '#source_branch_name' do
    context 'when source branch exists' do
      let(:raw_data) { double(base_data) }

      it 'returns branch ref' do
        expect(pull_request.source_branch_name).to eq 'feature'
      end
    end

    context 'when source branch does not exist' do
      let(:raw_data) { double(base_data.merge(head: removed_branch)) }

      it 'prefixes branch name with pull request number' do
        expect(pull_request.source_branch_name).to eq 'pull/1347/removed-branch'
      end
    end
  end

  describe '#target_branch_name' do
    context 'when source branch exists' do
      let(:raw_data) { double(base_data) }

      it 'returns branch ref' do
        expect(pull_request.target_branch_name).to eq 'master'
      end
    end

    context 'when target branch does not exist' do
      let(:raw_data) { double(base_data.merge(base: removed_branch)) }

      it 'prefixes branch name with pull request number' do
        expect(pull_request.target_branch_name).to eq 'pull/1347/removed-branch'
      end
    end
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

  describe '#url' do
    let(:raw_data) { double(base_data) }

    it 'return raw url' do
      expect(pull_request.url).to eq 'https://api.github.com/repos/octocat/Hello-World/pulls/1347'
    end
  end
end
