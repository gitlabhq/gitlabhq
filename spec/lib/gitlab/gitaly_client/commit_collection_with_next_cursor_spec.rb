# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::CommitCollectionWithNextCursor, feature_category: :gitaly do
  let_it_be(:project) { create(:project, :repository) }

  let(:message) { Struct.new(:pagination_cursor, :commits) }
  let(:pagination_cursor) { Struct.new(:next_cursor) }

  let(:next_cursor) { SecureRandom.uuid }
  let(:commit_1) { { id: 123 } }
  let(:commit_2) { { id: 234 } }

  let(:streamed_response) do
    [
      message.new(pagination_cursor: pagination_cursor.new(next_cursor: next_cursor), commits: [commit_1]),
      message.new(pagination_cursor: pagination_cursor.new, commits: [commit_2])
    ]
  end

  subject(:commit_collection_with_next_cursor) { described_class.new(streamed_response, project.repository) }

  describe '#next_cursor' do
    subject { commit_collection_with_next_cursor.next_cursor }

    it { is_expected.to eq(next_cursor) }
  end

  describe 'gitaly commit transmutation' do
    before do
      allow(Gitlab::Git::Commit).to receive(:new).and_call_original.twice
    end

    it 'calls Gitlab::Git::Commit.new with commit_1 and commit_2', :aggregate_failures do
      expect(commit_collection_with_next_cursor).to all be_a Gitlab::Git::Commit
      expect(commit_collection_with_next_cursor.count).to eq 2
      expect(Gitlab::Git::Commit).to have_received(:new).with(project.repository, commit_1).once
      expect(Gitlab::Git::Commit).to have_received(:new).with(project.repository, commit_2).once
    end
  end
end
