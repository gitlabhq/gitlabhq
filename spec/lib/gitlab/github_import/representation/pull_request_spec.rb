# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GithubImport::Representation::PullRequest do
  let(:created_at) { Time.new(2017, 1, 1, 12, 00) }
  let(:updated_at) { Time.new(2017, 1, 1, 12, 15) }
  let(:merged_at) { Time.new(2017, 1, 1, 12, 17) }

  shared_examples 'a PullRequest' do
    it 'returns an instance of PullRequest' do
      expect(pr).to be_an_instance_of(described_class)
    end

    context 'the returned PullRequest' do
      it 'includes the pull request number' do
        expect(pr.iid).to eq(42)
      end

      it 'includes the pull request title' do
        expect(pr.title).to eq('My Pull Request')
      end

      it 'includes the pull request description' do
        expect(pr.description).to eq('This is my pull request')
      end

      it 'includes the source branch name' do
        expect(pr.source_branch).to eq('my-feature')
      end

      it 'includes the source branch SHA' do
        expect(pr.source_branch_sha).to eq('123abc')
      end

      it 'includes the target branch name' do
        expect(pr.target_branch).to eq('master')
      end

      it 'includes the target branch SHA' do
        expect(pr.target_branch_sha).to eq('456def')
      end

      it 'includes the milestone number' do
        expect(pr.milestone_number).to eq(4)
      end

      it 'includes the user details' do
        expect(pr.author)
          .to be_an_instance_of(Gitlab::GithubImport::Representation::User)

        expect(pr.author.id).to eq(4)
        expect(pr.author.login).to eq('alice')
      end

      it 'includes the assignee details' do
        expect(pr.assignee)
          .to be_an_instance_of(Gitlab::GithubImport::Representation::User)

        expect(pr.assignee.id).to eq(4)
        expect(pr.assignee.login).to eq('alice')
      end

      it 'includes the created timestamp' do
        expect(pr.created_at).to eq(created_at)
      end

      it 'includes the updated timestamp' do
        expect(pr.updated_at).to eq(updated_at)
      end

      it 'includes the merged timestamp' do
        expect(pr.merged_at).to eq(merged_at)
      end

      it 'includes the source repository ID' do
        expect(pr.source_repository_id).to eq(400)
      end

      it 'includes the target repository ID' do
        expect(pr.target_repository_id).to eq(200)
      end

      it 'includes the source repository owner name' do
        expect(pr.source_repository_owner).to eq('alice')
      end

      it 'includes the pull request state' do
        expect(pr.state).to eq(:merged)
      end
    end
  end

  describe '.from_api_response' do
    let(:response) do
      double(
        :response,
        number: 42,
        title: 'My Pull Request',
        body: 'This is my pull request',
        state: 'closed',
        head: double(
          :head,
          sha: '123abc',
          ref: 'my-feature',
          repo: double(:repo, id: 400),
          user: double(:user, id: 4, login: 'alice')
        ),
        base: double(
          :base,
          sha: '456def',
          ref: 'master',
          repo: double(:repo, id: 200)
        ),
        milestone: double(:milestone, number: 4),
        user: double(:user, id: 4, login: 'alice'),
        assignee: double(:user, id: 4, login: 'alice'),
        created_at: created_at,
        updated_at: updated_at,
        merged_at: merged_at
      )
    end

    it_behaves_like 'a PullRequest' do
      let(:pr) { described_class.from_api_response(response) }
    end

    it 'does not set the user if the response did not include a user' do
      allow(response)
        .to receive(:user)
        .and_return(nil)

      pr = described_class.from_api_response(response)

      expect(pr.author).to be_nil
    end
  end

  describe '.from_json_hash' do
    it_behaves_like 'a PullRequest' do
      let(:hash) do
        {
          'iid' => 42,
          'title' => 'My Pull Request',
          'description' => 'This is my pull request',
          'source_branch' => 'my-feature',
          'source_branch_sha' => '123abc',
          'target_branch' => 'master',
          'target_branch_sha' => '456def',
          'source_repository_id' => 400,
          'target_repository_id' => 200,
          'source_repository_owner' => 'alice',
          'state' => 'closed',
          'milestone_number' => 4,
          'author' => { 'id' => 4, 'login' => 'alice' },
          'assignee' => { 'id' => 4, 'login' => 'alice' },
          'created_at' => created_at.to_s,
          'updated_at' => updated_at.to_s,
          'merged_at' => merged_at.to_s
        }
      end

      let(:pr) { described_class.from_json_hash(hash) }
    end

    it 'does not convert the author if it was not specified' do
      hash = {
        'iid' => 42,
        'title' => 'My Pull Request',
        'description' => 'This is my pull request',
        'source_branch' => 'my-feature',
        'source_branch_sha' => '123abc',
        'target_branch' => 'master',
        'target_branch_sha' => '456def',
        'source_repository_id' => 400,
        'target_repository_id' => 200,
        'source_repository_owner' => 'alice',
        'state' => 'closed',
        'milestone_number' => 4,
        'assignee' => { 'id' => 4, 'login' => 'alice' },
        'created_at' => created_at.to_s,
        'updated_at' => updated_at.to_s,
        'merged_at' => merged_at.to_s
      }

      pr = described_class.from_json_hash(hash)

      expect(pr.author).to be_nil
    end
  end

  describe '#state' do
    it 'returns :opened for an open pull request' do
      pr = described_class.new(state: :opened)

      expect(pr.state).to eq(:opened)
    end

    it 'returns :closed for a closed pull request' do
      pr = described_class.new(state: :closed)

      expect(pr.state).to eq(:closed)
    end

    it 'returns :merged for a merged pull request' do
      pr = described_class.new(state: :closed, merged_at: merged_at)

      expect(pr.state).to eq(:merged)
    end
  end

  describe '#cross_project?' do
    it 'returns false for a pull request submitted from the target project' do
      pr = described_class.new(source_repository_id: 1, target_repository_id: 1)

      expect(pr).not_to be_cross_project
    end

    it 'returns true for a pull request submitted from a different project' do
      pr = described_class.new(source_repository_id: 1, target_repository_id: 2)

      expect(pr).to be_cross_project
    end

    it 'returns true if no source repository is present' do
      pr = described_class.new(target_repository_id: 2)

      expect(pr).to be_cross_project
    end
  end

  describe '#formatted_source_branch' do
    context 'for a cross-project pull request' do
      it 'includes the owner name in the branch name' do
        pr = described_class.new(
          source_repository_owner: 'foo',
          source_branch: 'branch',
          target_branch: 'master',
          source_repository_id: 1,
          target_repository_id: 2
        )

        expect(pr.formatted_source_branch).to eq('github/fork/foo/branch')
      end
    end

    context 'for a regular pull request' do
      it 'returns the source branch name' do
        pr = described_class.new(
          source_repository_owner: 'foo',
          source_branch: 'branch',
          target_branch: 'master',
          source_repository_id: 1,
          target_repository_id: 1
        )

        expect(pr.formatted_source_branch).to eq('branch')
      end
    end

    context 'for a pull request with the same source and target branches' do
      it 'returns a generated source branch name' do
        pr = described_class.new(
          iid: 1,
          source_repository_owner: 'foo',
          source_branch: 'branch',
          target_branch: 'branch',
          source_repository_id: 1,
          target_repository_id: 1
        )

        expect(pr.formatted_source_branch).to eq('branch-1')
      end
    end
  end

  describe '#truncated_title' do
    it 'truncates the title to 255 characters' do
      object = described_class.new(title: 'm' * 300)

      expect(object.truncated_title.length).to eq(255)
    end

    it 'does not truncate the title if it is shorter than 255 characters' do
      object = described_class.new(title: 'foo')

      expect(object.truncated_title).to eq('foo')
    end
  end
end
