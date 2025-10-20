# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PoolRepository, feature_category: :source_code_management do
  describe 'associations' do
    it { is_expected.to belong_to(:shard) }
    it { is_expected.to belong_to(:organization).optional(true) }
    it { is_expected.to belong_to(:source_project) }
    it { is_expected.to have_many(:member_projects) }
  end

  describe 'before_validation callbacks' do
    let_it_be(:project) { create(:project) }
    let_it_be(:other_organization) { create(:organization) }

    context 'when organization is not set' do
      it 'assigns organization from the source project' do
        pool_repo = build(
          :pool_repository,
          source_project: project,
          organization: nil
        )

        expect(pool_repo.organization).to be_nil
        pool_repo.valid?
        expect(pool_repo.organization).to eq(pool_repo.source_project.organization)
      end
    end

    # This is an edge case because the key would initially be based on the
    # project's key, but the test exists to prove that we early return if
    # the organization exists.
    context 'when organization is set' do
      it 'retains the same organization' do
        pool_repo = build(
          :pool_repository,
          source_project: project,
          organization: other_organization
        )

        expect(pool_repo.organization).not_to be_nil
        pool_repo.valid?
        expect(pool_repo.organization).not_to eq(project.organization)
        expect(pool_repo.organization).to eq(other_organization)
      end
    end
  end

  describe 'validations' do
    let!(:pool_repository) { create(:pool_repository) }

    it { is_expected.to validate_presence_of(:shard) }
  end

  describe 'scopes' do
    let_it_be(:project1) { create(:project) }
    let_it_be(:project2) { create(:project) }
    let_it_be(:new_shard) { create(:shard, name: 'new') }
    let_it_be(:pool_repository1) { create(:pool_repository, source_project: project1, disk_path: 'disk_path') }
    let_it_be(:pool_repository2) do
      create(:pool_repository, source_project: project1, disk_path: 'disk_path', shard: new_shard)
    end

    let_it_be(:another_pool_repository) { create(:pool_repository, source_project: project2) }

    describe '.by_source_project' do
      subject { described_class.by_source_project(project1) }

      it 'returns pool repositories per source project from all shards' do
        is_expected.to match_array([pool_repository1, pool_repository2])
      end
    end

    describe '.by_disk_path_and_shard_name' do
      subject { described_class.by_disk_path_and_shard_name('disk_path', new_shard.name) }

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
        other_project = create(:project,
          :fork_repository, forked_from_project: pool.source_project, pool_repository: pool)
        pool.link_repository(other_project.repository)

        expect(::ObjectPool::DestroyWorker).not_to receive(:perform_async).with(pool.id)
        expect(pool.source_project.repository).to receive(:disconnect_alternates).and_call_original

        pool.unlink_repository(pool.source_project.repository)
      end
    end
  end

  describe '#object_pool' do
    subject { pool.object_pool }

    let(:pool) { build(:pool_repository, :ready, source_project: project, disk_path: disk_path) }
    let(:project) { build(:project) }
    let(:disk_path) { 'disk_path' }

    it 'returns an object pool instance' do
      is_expected.to be_a_kind_of(Gitlab::Git::ObjectPool)

      is_expected.to have_attributes(
        storage: pool.shard.name,
        relative_path: "#{pool.disk_path}.git",
        source_repository: pool.source_project.repository.raw,
        gl_project_path: pool.source_project.full_path
      )
    end

    context 'when source project is missing' do
      let(:project) { nil }

      it 'returns an object pool instance' do
        is_expected.to be_a_kind_of(Gitlab::Git::ObjectPool)

        is_expected.to have_attributes(
          storage: pool.shard.name,
          relative_path: "#{pool.disk_path}.git",
          source_repository: nil,
          gl_project_path: nil
        )
      end
    end
  end

  context 'with loose foreign key on pool_repositories.source_project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:project) }
      let_it_be(:model) { create(:pool_repository, source_project: parent) }
    end
  end

  context 'with state machine' do
    subject!(:pool_repository) { create(:pool_repository) }

    it { is_expected.to have_states :none, :scheduled, :ready, :failed, :obsolete }
    it { is_expected.to handle_events :schedule, when: :none }
    it { is_expected.to handle_events :mark_ready, when: :scheduled }
    it { is_expected.to handle_events :mark_ready, when: :failed }
    it { is_expected.to handle_events :mark_failed, :mark_obsolete, :reinitialize }

    it 'starts as none' do
      expect(pool_repository).to be_none
    end
  end

  describe '#reinitialize' do
    context 'when object_pool exists' do
      subject(:pool_repository) { create(:pool_repository, :ready) }

      it 'does not reinitialize' do
        expect { pool_repository.reinitialize }.to not_change { pool_repository.state }
      end
    end

    context 'when object_pool does not exist' do
      subject(:pool_repository) { create(:pool_repository, :ready) }

      it 'allows reinitializing the state machine' do
        pool_repository.delete_object_pool

        expect { pool_repository.reinitialize }.to change { pool_repository.state }.from('ready').to('none')
      end
    end

    context 'when object_pool is already scheduled' do
      subject(:pool_repository) { create(:pool_repository, :scheduled) }

      it 'does not reinitialize' do
        expect { pool_repository.reinitialize }.to not_change { pool_repository.state }
      end
    end
  end
end
