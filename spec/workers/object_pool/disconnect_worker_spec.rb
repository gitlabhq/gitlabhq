# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ObjectPool::DisconnectWorker, feature_category: :source_code_management do
  subject(:perform) { described_class.new.perform(project_id, pool.disk_path) }

  describe '#perform' do
    let(:pool) { create(:pool_repository, :ready) }
    let(:project) { pool.source_project }
    let(:project_id) { project.id }
    let(:repository) { instance_double(Gitlab::Git::Repository) }

    before do
      allow_next_found_instance_of(Project) do |found_project|
        allow(found_project).to receive(:repository).and_return(repository)
      end
    end

    context 'when a previous run already completed' do
      before do
        project.update_column(:pool_repository_id, nil)
      end

      it 'does not disconnect alternates or schedule pool removal', :aggregate_failures do
        expect(repository).not_to receive(:disconnect_alternates)
        expect(ObjectPool::DestroyWorker).not_to receive(:perform_async)

        perform

        expect(pool.reload).not_to be_obsolete
      end
    end

    context 'when the project is still a member of the pool' do
      it 'disconnects alternates, removes the member, and schedules pool removal', :aggregate_failures do
        expect(repository).to receive(:disconnect_alternates)
        expect(ObjectPool::DestroyWorker).to receive(:perform_async).with(pool.id).once

        perform

        expect(project.reload.pool_repository).to be_nil
        expect(pool.reload).to be_obsolete
      end
    end

    context 'when a storage move replaced the pool with one on another shard' do
      let(:new_pool) do
        create(
          :pool_repository,
          disk_path: pool.disk_path,
          shard: create(:shard, name: 'alternate'),
          source_project: project
        )
      end

      before do
        project.update_column(:pool_repository_id, new_pool.id)
      end

      it 'disconnects alternates and removes membership from the replacement pool', :aggregate_failures do
        expect(repository).to receive(:disconnect_alternates)
        expect(ObjectPool::DestroyWorker).to receive(:perform_async).with(new_pool.id).once

        perform

        expect(project.reload.pool_repository).to be_nil
        expect(new_pool.reload).to be_obsolete
      end
    end

    context 'when the project joined a genuinely new pool' do
      let(:new_pool) { create(:pool_repository, :ready) }

      before do
        project.update_column(:pool_repository_id, new_pool.id)
      end

      it 'preserves the new membership without disconnecting alternates', :aggregate_failures do
        expect(repository).not_to receive(:disconnect_alternates)
        expect(ObjectPool::DestroyWorker).not_to receive(:perform_async)

        perform

        expect(project.reload.pool_repository).to eq(new_pool)
        expect(pool.reload).not_to be_obsolete
      end
    end

    context 'when the project is missing' do
      let(:project_id) { non_existing_record_id }

      it 'does not disconnect alternates or obsolete the pool', :aggregate_failures do
        expect(ObjectPool::DestroyWorker).not_to receive(:perform_async)

        expect { perform }.not_to raise_error
        expect(pool.reload).not_to be_obsolete
      end
    end
  end

  describe '.sidekiq_retries_exhausted' do
    it 'tracks the permanent failure' do
      project_id = non_existing_record_id
      pool_disk_path = '@pools/aa/bbbb'
      exception = StandardError.new('Gitaly unavailable')

      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        exception,
        project_id: project_id,
        pool_disk_path: pool_disk_path
      )

      described_class.sidekiq_retries_exhausted_block.call(
        { 'args' => [project_id, pool_disk_path] }, exception
      )
    end
  end

  it_behaves_like 'an idempotent worker' do
    let(:pool) { create(:pool_repository, :ready) }
    let(:project) { pool.source_project }
    let(:job_args) { [project.id, pool.disk_path] }
  end
end
