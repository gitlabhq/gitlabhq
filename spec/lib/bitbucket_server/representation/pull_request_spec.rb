# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BitbucketServer::Representation::PullRequest, feature_category: :importers do
  let(:sample_data) { Gitlab::Json.parse(fixture_file('importers/bitbucket_server/pull_request.json')) }

  subject { described_class.new(sample_data) }

  describe '#author' do
    it { expect(subject.author).to eq('root') }
  end

  describe '#author_email' do
    it { expect(subject.author_email).to eq('joe.montana@49ers.com') }
  end

  describe '#author_username' do
    it 'returns username' do
      expect(subject.author_username).to eq('username')
    end

    context 'when username is absent' do
      before do
        sample_data['author']['user'].delete('username')
      end

      it 'returns slug' do
        expect(subject.author_username).to eq('slug')
      end
    end

    context 'when slug and username are absent' do
      before do
        sample_data['author']['user'].delete('username')
        sample_data['author']['user'].delete('slug')
      end

      it 'returns displayName' do
        expect(subject.author_username).to eq('displayName')
      end
    end
  end

  describe '#description' do
    it { expect(subject.description).to eq('Test') }
  end

  describe '#reviewers' do
    it { expect(subject.reviewers.count).to eq(2) }
  end

  describe '#iid' do
    it { expect(subject.iid).to eq(7) }
  end

  describe '#state' do
    it { expect(subject.state).to eq('merged') }

    context 'declined pull requests' do
      before do
        sample_data['state'] = 'DECLINED'
      end

      it 'returns closed' do
        expect(subject.state).to eq('closed')
      end
    end

    context 'open pull requests' do
      before do
        sample_data['state'] = 'OPEN'
      end

      it 'returns open' do
        expect(subject.state).to eq('opened')
      end
    end
  end

  describe '#merged?' do
    it { expect(subject.merged?).to be_truthy }
  end

  describe '#closed?' do
    it { expect(subject.closed?).to be_falsey }

    context 'for declined pull requests' do
      before do
        sample_data['state'] = 'DECLINED'
      end

      it { expect(subject.closed?).to be_truthy }
    end
  end

  describe '#created_at' do
    it { expect(subject.created_at.to_i).to eq(sample_data['createdDate'] / 1000) }
  end

  describe '#updated_at' do
    it { expect(subject.updated_at.to_i).to eq(sample_data['updatedDate'] / 1000) }
  end

  describe '#title' do
    it { expect(subject.title).to eq('Added a new line') }
  end

  describe '#source_branch_name' do
    it { expect(subject.source_branch_name).to eq('refs/heads/root/CODE_OF_CONDUCTmd-1530600625006') }
  end

  describe '#source_branch_sha' do
    it { expect(subject.source_branch_sha).to eq('074e2b4dddc5b99df1bf9d4a3f66cfc15481fdc8') }
  end

  describe '#target_branch_name' do
    it { expect(subject.target_branch_name).to eq('refs/heads/master') }
  end

  describe '#target_branch_sha' do
    it { expect(subject.target_branch_sha).to eq('839fa9a2d434eb697815b8fcafaecc51accfdbbc') }
  end

  describe '#to_hash' do
    it do
      expect(subject.to_hash).to match(
        a_hash_including(
          author_email: "joe.montana@49ers.com",
          author_username: "username",
          author: "root",
          description: "Test",
          reviewers: contain_exactly(
            hash_including('user' => hash_including('emailAddress' => 'jane@doe.com', 'slug' => 'jane_doe')),
            hash_including('user' => hash_including('emailAddress' => 'john@smith.com', 'slug' => 'john_smith'))
          ),
          source_branch_name: "refs/heads/root/CODE_OF_CONDUCTmd-1530600625006",
          source_branch_sha: "074e2b4dddc5b99df1bf9d4a3f66cfc15481fdc8",
          target_branch_name: "refs/heads/master",
          target_branch_sha: "839fa9a2d434eb697815b8fcafaecc51accfdbbc",
          title: "Added a new line"
        )
      )
    end
  end
end
