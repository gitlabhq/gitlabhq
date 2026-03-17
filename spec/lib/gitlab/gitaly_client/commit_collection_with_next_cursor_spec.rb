# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GitalyClient::CommitCollectionWithNextCursor, feature_category: :gitaly do
  let_it_be(:project) { create(:project, :repository) }

  let(:message) { Struct.new(:pagination_cursor, :commits) }
  let(:pagination_cursor) { Struct.new(:next_cursor) }

  let(:next_cursor) { SecureRandom.uuid }
  let(:commit_1) { { id: 123 } }
  let(:commit_2) { { id: 234 } }

  subject(:collection) { described_class.new(streamed_response, project.repository) }

  describe '#next_cursor' do
    subject { collection.next_cursor }

    context 'when cursor is in the first response' do
      let(:streamed_response) do
        [
          message.new(pagination_cursor: pagination_cursor.new(next_cursor: next_cursor), commits: [commit_1]),
          message.new(pagination_cursor: pagination_cursor.new, commits: [commit_2])
        ]
      end

      it { is_expected.to eq(next_cursor) }
    end

    context 'when cursor is in a later response' do
      let(:streamed_response) do
        [
          message.new(pagination_cursor: nil, commits: [commit_1]),
          message.new(pagination_cursor: pagination_cursor.new(next_cursor: next_cursor), commits: [commit_2])
        ]
      end

      it { is_expected.to eq(next_cursor) }
    end

    context 'when cursor is in a final response with no commits' do
      let(:streamed_response) do
        [
          message.new(pagination_cursor: nil, commits: [commit_1]),
          message.new(pagination_cursor: pagination_cursor.new(next_cursor: next_cursor), commits: [])
        ]
      end

      it { is_expected.to eq(next_cursor) }

      it 'collects all commits' do
        expect(collection.count).to eq 1
      end
    end

    context 'when no cursor is present' do
      let(:streamed_response) do
        [
          message.new(pagination_cursor: nil, commits: [commit_1]),
          message.new(pagination_cursor: pagination_cursor.new(next_cursor: ''), commits: [commit_2])
        ]
      end

      it { is_expected.to be_nil }
    end
  end

  describe 'gitaly commit transmutation' do
    let(:streamed_response) do
      [
        message.new(pagination_cursor: pagination_cursor.new(next_cursor: next_cursor), commits: [commit_1]),
        message.new(pagination_cursor: pagination_cursor.new, commits: [commit_2])
      ]
    end

    before do
      allow(Gitlab::Git::Commit).to receive(:new).and_call_original.twice
    end

    it 'creates Gitlab::Git::Commit objects for each commit' do
      expect(collection).to all be_a Gitlab::Git::Commit
      expect(collection.count).to eq 2
      expect(Gitlab::Git::Commit).to have_received(:new).with(project.repository, commit_1).once
      expect(Gitlab::Git::Commit).to have_received(:new).with(project.repository, commit_2).once
    end
  end
end
