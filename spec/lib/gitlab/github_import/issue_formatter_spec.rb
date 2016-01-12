require 'spec_helper'

describe Gitlab::GithubImport::IssueFormatter, lib: true do
  let!(:project) { create(:project, namespace: create(:namespace, path: 'octocat')) }
  let(:octocat) { OpenStruct.new(id: 123456, login: 'octocat') }
  let(:created_at) { DateTime.strptime('2011-01-26T19:01:12Z') }
  let(:updated_at) { DateTime.strptime('2011-01-27T19:01:12Z') }

  let(:base_data) do
    {
      number: 1347,
      state: 'open',
      title: 'Found a bug',
      body: "I'm having a problem with this.",
      assignee: nil,
      user: octocat,
      comments: 0,
      pull_request: nil,
      created_at: created_at,
      updated_at: updated_at,
      closed_at: nil
    }
  end

  subject(:issue) { described_class.new(project, raw_data)}

  describe '#attributes' do
    context 'when issue is open' do
      let(:raw_data) { OpenStruct.new(base_data.merge(state: 'open')) }

      it 'returns formatted attributes' do
        expected = {
          project: project,
          title: 'Found a bug',
          description: "*Created by: octocat*\n\nI'm having a problem with this.",
          state: 'opened',
          author_id: project.creator_id,
          assignee_id: nil,
          created_at: created_at,
          updated_at: updated_at
        }

        expect(issue.attributes).to eq(expected)
      end
    end

    context 'when issue is closed' do
      let(:closed_at) { DateTime.strptime('2011-01-28T19:01:12Z') }
      let(:raw_data) { OpenStruct.new(base_data.merge(state: 'closed', closed_at: closed_at)) }

      it 'returns formatted attributes' do
        expected = {
          project: project,
          title: 'Found a bug',
          description: "*Created by: octocat*\n\nI'm having a problem with this.",
          state: 'closed',
          author_id: project.creator_id,
          assignee_id: nil,
          created_at: created_at,
          updated_at: closed_at
        }

        expect(issue.attributes).to eq(expected)
      end
    end

    context 'when it is assigned to someone' do
      let(:raw_data) { OpenStruct.new(base_data.merge(assignee: octocat)) }

      it 'returns nil as assignee_id when is not a GitLab user' do
        expect(issue.attributes.fetch(:assignee_id)).to be_nil
      end

      it 'returns GitLab user id as assignee_id when is a GitLab user' do
        gl_user = create(:omniauth_user, extern_uid: octocat.id, provider: 'github')

        expect(issue.attributes.fetch(:assignee_id)).to eq gl_user.id
      end
    end

    context 'when author is a GitLab user' do
      let(:raw_data) { OpenStruct.new(base_data.merge(user: octocat)) }

      it 'returns project#creator_id as author_id when is not a GitLab user' do
        expect(issue.attributes.fetch(:author_id)).to eq project.creator_id
      end

      it 'returns GitLab user id as author_id when is a GitLab user' do
        gl_user = create(:omniauth_user, extern_uid: octocat.id, provider: 'github')

        expect(issue.attributes.fetch(:author_id)).to eq gl_user.id
      end
    end
  end

  describe '#has_comments?' do
    context 'when number of comments is greater than zero' do
      let(:raw_data) { OpenStruct.new(base_data.merge(comments: 1)) }

      it 'returns true' do
        expect(issue.has_comments?).to eq true
      end
    end

    context 'when number of comments is equal to zero' do
      let(:raw_data) { OpenStruct.new(base_data.merge(comments: 0)) }

      it 'returns false' do
        expect(issue.has_comments?).to eq false
      end
    end
  end

  describe '#number' do
    let(:raw_data) { OpenStruct.new(base_data.merge(number: 1347)) }

    it 'returns pull request number' do
      expect(issue.number).to eq 1347
    end
  end

  describe '#valid?' do
    context 'when mention a pull request' do
      let(:raw_data) { OpenStruct.new(base_data.merge(pull_request: OpenStruct.new)) }

      it 'returns false' do
        expect(issue.valid?).to eq false
      end
    end

    context 'when does not mention a pull request' do
      let(:raw_data) { OpenStruct.new(base_data.merge(pull_request: nil)) }

      it 'returns true' do
        expect(issue.valid?).to eq true
      end
    end
  end
end
