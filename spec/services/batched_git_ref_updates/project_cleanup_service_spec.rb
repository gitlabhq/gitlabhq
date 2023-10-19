# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BatchedGitRefUpdates::ProjectCleanupService, feature_category: :gitaly do
  let(:service) { described_class.new(project1.id) }
  let_it_be(:project1) { create(:project, :repository) }
  let_it_be(:project2) { create(:project, :repository) }
  let!(:project1_ref1) do
    BatchedGitRefUpdates::Deletion.create!(project_id: project1.id, ref: 'refs/test/project1-ref1')
  end

  let!(:project1_ref2) do
    BatchedGitRefUpdates::Deletion.create!(project_id: project1.id, ref: 'refs/test/project1-ref2')
  end

  let!(:project1_ref3) do
    BatchedGitRefUpdates::Deletion.create!(project_id: project1.id, ref: 'refs/test/already-processed',
      status: :processed)
  end

  let!(:project2_ref1) do
    BatchedGitRefUpdates::Deletion.create!(project_id: project2.id, ref: 'refs/test/project2-ref1')
  end

  describe '#execute' do
    before do
      project1.repository.create_ref('HEAD', 'refs/test/ref-to-not-be-deleted')
      project1.repository.create_ref('HEAD', project1_ref1.ref)
      project1.repository.create_ref('HEAD', project1_ref2.ref)
      project1.repository.create_ref('HEAD', 'refs/test/already-processed')
      project2.repository.create_ref('HEAD', project2_ref1.ref)
    end

    it 'deletes the named refs in batches for the given project only' do
      expect(test_refs(project1)).to include(
        'refs/test/ref-to-not-be-deleted',
        'refs/test/already-processed',
        'refs/test/project1-ref1',
        'refs/test/project1-ref1',
        'refs/test/project1-ref2')

      service.execute

      expect(test_refs(project1)).to include(
        'refs/test/already-processed',
        'refs/test/ref-to-not-be-deleted')

      expect(test_refs(project1)).not_to include(
        'refs/test/project1-ref1',
        'refs/test/project1-ref2')

      expect(test_refs(project2)).to include('refs/test/project2-ref1')
    end

    it 'handles duplicates' do
      BatchedGitRefUpdates::Deletion.create!(project_id: project1.id, ref: 'refs/test/some-duplicate')
      BatchedGitRefUpdates::Deletion.create!(project_id: project1.id, ref: 'refs/test/some-duplicate')

      service.execute

      expect(test_refs(project1)).not_to include('refs/test/some-duplicate')
    end

    it 'marks the processed BatchedGitRefUpdates::Deletion as processed' do
      service.execute

      expect(BatchedGitRefUpdates::Deletion.status_pending.map(&:ref)).to contain_exactly('refs/test/project2-ref1')
      expect(BatchedGitRefUpdates::Deletion.status_processed.map(&:ref)).to contain_exactly(
        'refs/test/project1-ref1',
        'refs/test/project1-ref2',
        'refs/test/already-processed')
    end

    it 'returns stats' do
      result = service.execute

      expect(result[:total_deletes]).to eq(2)
    end

    it 'acquires a lock for the given project_id to avoid running duplicate instances' do
      expect(service).to receive(:in_lock) # Mock and don't yield
        .with("#{described_class}/#{project1.id}", retries: 0, ttl: described_class::LOCK_TIMEOUT)

      expect { service.execute }.not_to change { BatchedGitRefUpdates::Deletion.status_pending.count }
    end

    it 'does nothing when the project does not exist' do
      result = described_class.new(non_existing_record_id).execute

      expect(result[:total_deletes]).to eq(0)
    end

    it 'stops after it reaches limit of deleted refs' do
      stub_const("#{described_class}::QUERY_BATCH_SIZE", 1)
      stub_const("#{described_class}::MAX_DELETES", 1)

      result = service.execute

      expect(result[:total_deletes]).to eq(1)
    end

    def test_refs(project)
      project.repository.list_refs(['refs/test/']).map(&:name)
    end
  end
end
