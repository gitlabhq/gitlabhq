# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::LfsPointers::LfsListService, feature_category: :source_code_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.creator }
  let_it_be(:updated_revisions) { ['refs/remotes/upstream/main', 'refs/remotes/upstream/dev'] }

  let(:mock_blobs) do
    [
      instance_double(Gitlab::Git::Blob, lfs_oid: 'oid1', lfs_size: 123),
      instance_double(Gitlab::Git::Blob, lfs_oid: 'oid2', lfs_size: 456)
    ]
  end

  let(:mock_lfs_changes) { instance_double(Gitlab::Git::LfsChanges) }
  let(:expected_hash) { { 'oid1' => 123, 'oid2' => 456 } }

  subject(:lfs_list_service) { described_class.new(project, user, { updated_revisions: updated_revisions }) }

  describe '#execute' do
    context 'when LFS is enabled' do
      before do
        allow(project).to receive(:lfs_enabled?).and_return(true)
      end

      context 'when updated_revisions is not ["--all"]' do
        it 'returns hash of lfs pointers from new_pointers' do
          expect_next_instance_of(Gitlab::Git::LfsChanges, project.repository, updated_revisions) do |lfs_changes|
            expect(lfs_changes).to receive(:new_pointers)
              .with(not_in: [])
              .and_return(mock_blobs)
          end

          result = lfs_list_service.execute
          expect(result).to eq(expected_hash)
        end
      end

      context 'when updated_revisions is ["--all"]' do
        let(:updated_revisions) { ['--all'] }

        it 'returns hash of lfs pointers from all_pointers' do
          expect_next_instance_of(Gitlab::Git::LfsChanges, project.repository) do |lfs_changes|
            expect(lfs_changes).to receive(:all_pointers)
              .and_return(mock_blobs)
          end

          result = lfs_list_service.execute
          expect(result).to eq(expected_hash)
        end
      end

      context 'when updated_revisions is nil (import scenario)' do
        let(:updated_revisions) { nil }

        it 'returns hash of lfs pointers from all_pointers' do
          expect_next_instance_of(Gitlab::Git::LfsChanges, project.repository) do |lfs_changes|
            expect(lfs_changes).to receive(:all_pointers)
              .and_return(mock_blobs)
          end

          result = lfs_list_service.execute
          expect(result).to eq(expected_hash)
        end
      end

      context 'with mirroring_lfs_optimization feature flag disabled' do
        before do
          stub_feature_flags(mirroring_lfs_optimization: false)
        end

        it 'returns hash of lfs pointers from all_pointers' do
          expect_next_instance_of(Gitlab::Git::LfsChanges, project.repository) do |lfs_changes|
            expect(lfs_changes).to receive(:all_pointers)
              .and_return(mock_blobs)
          end

          result = lfs_list_service.execute
          expect(result).to eq(expected_hash)
        end
      end
    end

    context 'when LFS is disabled' do
      before do
        allow(project).to receive(:lfs_enabled?).and_return(false)
      end

      it 'returns empty hash' do
        expect(Gitlab::Git::LfsChanges).not_to receive(:new)

        expect(lfs_list_service.execute).to eq({})
      end
    end
  end
end
