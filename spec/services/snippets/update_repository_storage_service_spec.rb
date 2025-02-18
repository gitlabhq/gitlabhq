# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Snippets::UpdateRepositoryStorageService, feature_category: :source_code_management do
  subject { described_class.new(repository_storage_move) }

  describe "#execute" do
    let_it_be_with_reload(:snippet) { create(:project_snippet, :repository) }
    let_it_be(:destination) { 'test_second_storage' }
    let_it_be(:checksum) { snippet.repository.checksum }

    let(:repository_storage_move_state) { :scheduled }
    let(:repository_storage_move) { create(:snippet_repository_storage_move, repository_storage_move_state, container: snippet, destination_storage_name: destination) }
    let(:snippet_repository_double) { double(:repository) }
    let(:original_snippet_repository_double) { double(:repository) }

    before do
      allow(Gitlab.config.repositories.storages).to receive(:keys).and_return(%w[default test_second_storage])
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with('default').and_call_original
      allow(Gitlab::GitalyClient).to receive(:filesystem_id).with(destination).and_return(SecureRandom.uuid)
      allow(Gitlab::Git::Repository).to receive(:new).and_call_original
      allow(Gitlab::Git::Repository).to receive(:new)
        .with(destination, snippet.repository.raw.relative_path, snippet.repository.gl_repository, snippet.repository.full_path)
        .and_return(snippet_repository_double)
      allow(Gitlab::Git::Repository).to receive(:new)
        .with('default', snippet.repository.raw.relative_path, nil, nil)
        .and_return(original_snippet_repository_double)
    end

    context 'when the move succeeds' do
      it 'moves the repository to the new storage and unmarks the repository as read-only' do
        expect(snippet_repository_double).to receive(:replicate)
          .with(snippet.repository.raw, partition_hint: "")
        expect(snippet_repository_double).to receive(:checksum)
          .and_return(checksum)
        expect(original_snippet_repository_double).to receive(:remove)

        result = subject.execute
        snippet.reload

        expect(result).to be_success
        expect(snippet).not_to be_repository_read_only
        expect(snippet.repository_storage).to eq(destination)
        expect(snippet.snippet_repository.shard_name).to eq(destination)
        expect(repository_storage_move.reload).to be_finished
        expect(repository_storage_move.error_message).to be_nil
      end
    end

    context 'when the filesystems are the same' do
      before do
        expect(Gitlab::GitalyClient).to receive(:filesystem_id).twice.and_return(SecureRandom.uuid)
      end

      it 'updates the database without trying to move the repository', :aggregate_failures do
        result = subject.execute
        snippet.reload

        expect(result).to be_success
        expect(snippet).not_to be_repository_read_only
        expect(snippet.repository_storage).to eq(destination)
        expect(snippet.snippet_repository.shard_name).to eq(destination)
      end
    end

    context 'when the move fails' do
      it 'unmarks the repository as read-only without updating the repository storage' do
        expect(snippet_repository_double).to receive(:replicate)
          .with(snippet.repository.raw, partition_hint: "")
          .and_raise(Gitlab::Git::CommandError, 'Boom')
        expect(snippet_repository_double).to receive(:remove)

        expect do
          subject.execute
        end.to raise_error(Gitlab::Git::CommandError)

        expect(snippet).not_to be_repository_read_only
        expect(snippet.repository_storage).to eq('default')
        expect(repository_storage_move).to be_failed
        expect(repository_storage_move.error_message).to eq('Boom')
      end
    end

    context 'when the cleanup fails' do
      it 'sets the correct state' do
        expect(snippet_repository_double).to receive(:replicate)
          .with(snippet.repository.raw, partition_hint: "")
        expect(snippet_repository_double).to receive(:checksum)
          .and_return(checksum)
        expect(original_snippet_repository_double).to receive(:remove)
          .and_raise(Gitlab::Git::CommandError)

        expect do
          subject.execute
        end.to raise_error(Gitlab::Git::CommandError)

        expect(repository_storage_move).to be_cleanup_failed
      end
    end

    context 'when the checksum does not match' do
      it 'unmarks the repository as read-only without updating the repository storage' do
        expect(snippet_repository_double).to receive(:replicate)
          .with(snippet.repository.raw, partition_hint: "")
        expect(snippet_repository_double).to receive(:checksum)
          .and_return('not matching checksum')
        expect(snippet_repository_double).to receive(:remove)

        expect do
          subject.execute
        end.to raise_error(::Repositories::ReplicateService::Error, /Failed to verify snippet repository checksum from \w+ to not matching checksum/)

        expect(snippet).not_to be_repository_read_only
        expect(snippet.repository_storage).to eq('default')
      end
    end

    context 'when the repository move is finished' do
      let(:repository_storage_move_state) { :finished }

      it 'is idempotent' do
        expect do
          result = subject.execute

          expect(result).to be_success
        end.not_to change(repository_storage_move, :state)
      end
    end

    context 'when the repository move is failed' do
      let(:repository_storage_move_state) { :failed }

      it 'is idempotent' do
        expect do
          result = subject.execute

          expect(result).to be_success
        end.not_to change(repository_storage_move, :state)
      end
    end
  end
end
