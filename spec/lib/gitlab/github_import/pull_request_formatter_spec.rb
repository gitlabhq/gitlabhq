require 'spec_helper'

describe Gitlab::GithubImport::PullRequestFormatter, lib: true do
  let(:project) { create(:project) }
  let(:repository) { OpenStruct.new(id: 1, fork: false) }
  let(:source_repo) { repository }
  let(:source_branch) { OpenStruct.new(ref: 'feature', repo: source_repo) }
  let(:target_repo) { repository }
  let(:target_branch) { OpenStruct.new(ref: 'master', repo: target_repo) }
  let(:octocat) { OpenStruct.new(id: 123456, login: 'octocat') }
  let(:created_at) { DateTime.strptime('2011-01-26T19:01:12Z') }
  let(:updated_at) { DateTime.strptime('2011-01-27T19:01:12Z') }
  let(:base_data) do
    {
      number: 1347,
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
      merged_at: nil
    }
  end

  subject(:pull_request) { described_class.new(project, raw_data)}

  describe '#attributes' do
    context 'when pull request is open' do
      let(:raw_data) { OpenStruct.new(base_data.merge(state: 'open')) }

      it 'returns formatted attributes' do
        expected = {
          title: 'New feature',
          description: "*Created by: octocat*\n\nPlease pull these awesome changes",
          source_project: project,
          source_branch: 'feature',
          target_project: project,
          target_branch: 'master',
          state: 'opened',
          author_id: project.creator_id,
          assignee_id: nil,
          created_at: created_at,
          updated_at: updated_at
        }

        expect(pull_request.attributes).to eq(expected)
      end
    end

    context 'when pull request is closed' do
      let(:closed_at) { DateTime.strptime('2011-01-28T19:01:12Z') }
      let(:raw_data) { OpenStruct.new(base_data.merge(state: 'closed', closed_at: closed_at)) }

      it 'returns formatted attributes' do
        expected = {
          title: 'New feature',
          description: "*Created by: octocat*\n\nPlease pull these awesome changes",
          source_project: project,
          source_branch: 'feature',
          target_project: project,
          target_branch: 'master',
          state: 'closed',
          author_id: project.creator_id,
          assignee_id: nil,
          created_at: created_at,
          updated_at: closed_at
        }

        expect(pull_request.attributes).to eq(expected)
      end
    end

    context 'when pull request is merged' do
      let(:merged_at) { DateTime.strptime('2011-01-28T13:01:12Z') }
      let(:raw_data) { OpenStruct.new(base_data.merge(state: 'closed', merged_at: merged_at)) }

      it 'returns formatted attributes' do
        expected = {
          title: 'New feature',
          description: "*Created by: octocat*\n\nPlease pull these awesome changes",
          source_project: project,
          source_branch: 'feature',
          target_project: project,
          target_branch: 'master',
          state: 'merged',
          author_id: project.creator_id,
          assignee_id: nil,
          created_at: created_at,
          updated_at: merged_at
        }

        expect(pull_request.attributes).to eq(expected)
      end
    end

    context 'when it is assigned to someone' do
      let(:raw_data) { OpenStruct.new(base_data.merge(assignee: octocat)) }

      it 'returns nil as assignee_id when is not a GitLab user' do
        expect(pull_request.attributes.fetch(:assignee_id)).to be_nil
      end

      it 'returns GitLab user id as assignee_id when is a GitLab user' do
        gl_user = create(:omniauth_user, extern_uid: octocat.id, provider: 'github')

        expect(pull_request.attributes.fetch(:assignee_id)).to eq gl_user.id
      end
    end

    context 'when author is a GitLab user' do
      let(:raw_data) { OpenStruct.new(base_data.merge(user: octocat)) }

      it 'returns project#creator_id as author_id when is not a GitLab user' do
        expect(pull_request.attributes.fetch(:author_id)).to eq project.creator_id
      end

      it 'returns GitLab user id as author_id when is a GitLab user' do
        gl_user = create(:omniauth_user, extern_uid: octocat.id, provider: 'github')

        expect(pull_request.attributes.fetch(:author_id)).to eq gl_user.id
      end
    end
  end

  describe '#number' do
    let(:raw_data) { OpenStruct.new(base_data.merge(number: 1347)) }

    it 'returns pull request number' do
      expect(pull_request.number).to eq 1347
    end
  end

  describe '#valid?' do
    let(:invalid_branch) { OpenStruct.new(ref: 'invalid-branch') }

    context 'when source, and target repositories are the same' do
      context 'and source and target branches exists' do
        let(:raw_data) { OpenStruct.new(base_data.merge(head: source_branch, base: target_branch)) }

        it 'returns true' do
          expect(pull_request.valid?).to eq true
        end
      end

      context 'and source branch doesn not exists' do
        let(:raw_data) { OpenStruct.new(base_data.merge(head: invalid_branch, base: target_branch)) }

        it 'returns false' do
          expect(pull_request.valid?).to eq false
        end
      end

      context 'and target branch doesn not exists' do
        let(:raw_data) { OpenStruct.new(base_data.merge(head: source_branch, base: invalid_branch)) }

        it 'returns false' do
          expect(pull_request.valid?).to eq false
        end
      end
    end

    context 'when source repo is a fork' do
      let(:source_repo) { OpenStruct.new(id: 2, fork: true) }
      let(:raw_data) { OpenStruct.new(base_data) }

      it 'returns false' do
        expect(pull_request.valid?).to eq false
      end
    end

    context 'when target repo is a fork' do
      let(:target_repo) { OpenStruct.new(id: 2, fork: true) }
      let(:raw_data) { OpenStruct.new(base_data) }

      it 'returns false' do
        expect(pull_request.valid?).to eq false
      end
    end
  end
end
