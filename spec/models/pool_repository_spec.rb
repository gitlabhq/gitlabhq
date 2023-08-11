# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PoolRepository, feature_category: :source_code_management do
  describe 'associations' do
    it { is_expected.to belong_to(:shard) }
    it { is_expected.to belong_to(:source_project) }
    it { is_expected.to have_many(:member_projects) }
  end

  describe 'validations' do
    let!(:pool_repository) { create(:pool_repository) }

    it { is_expected.to validate_presence_of(:shard) }
    it { is_expected.to validate_presence_of(:source_project) }
  end

  describe 'scopes' do
    let_it_be(:project1) { create(:project) }
    let_it_be(:project2) { create(:project) }
    let_it_be(:new_shard) { create(:shard, name: 'new') }
    let_it_be(:pool_repository1) { create(:pool_repository, source_project: project1) }
    let_it_be(:pool_repository2) { create(:pool_repository, source_project: project1, shard: new_shard) }
    let_it_be(:another_pool_repository) { create(:pool_repository, source_project: project2) }

    describe '.by_source_project' do
      subject { described_class.by_source_project(project1) }

      it 'returns pool repositories per source project from all shards' do
        is_expected.to match_array([pool_repository1, pool_repository2])
      end
    end

    describe '.by_source_project_and_shard_name' do
      subject { described_class.by_source_project_and_shard_name(project1, new_shard.name) }

      it 'returns only a requested pool repository' do
        is_expected.to match_array([pool_repository2])
      end
    end
  end

  describe '#disk_path' do
    it 'sets the hashed disk_path' do
      pool = create(:pool_repository)

      expect(pool.disk_path).to match(%r{\A@pools/\h{2}/\h{2}/\h{64}})
    end

    it 'keeps disk_path if already provided' do
      pool = create(:pool_repository, disk_path: '@pools/aa/bbbb')

      expect(pool.disk_path).to eq('@pools/aa/bbbb')
    end
  end

  describe '#unlink_repository' do
    let(:pool) { create(:pool_repository, :ready) }

    before do
      pool.link_repository(pool.source_project.repository)
    end

    context 'when the last member leaves' do
      it 'schedules pool removal' do
        expect(::ObjectPool::DestroyWorker).to receive(:perform_async).with(pool.id).and_call_original
        expect(pool.source_project.repository).to receive(:disconnect_alternates).and_call_original

        pool.unlink_repository(pool.source_project.repository)
      end
    end

    context 'when skipping disconnect' do
      it 'does not change the alternates file' do
        expect(pool.source_project.repository).not_to receive(:disconnect_alternates)

        pool.unlink_repository(pool.source_project.repository, disconnect: false)
      end
    end

    context 'when the second member leaves' do
      it 'does not schedule pool removal' do
        other_project = create(:project, :repository, pool_repository: pool)
        pool.link_repository(other_project.repository)

        expect(::ObjectPool::DestroyWorker).not_to receive(:perform_async).with(pool.id)
        expect(pool.source_project.repository).to receive(:disconnect_alternates).and_call_original

        pool.unlink_repository(pool.source_project.repository)
      end
    end
  end
end
