# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GitGarbageCollectWorker do
  let_it_be(:project) { create(:project, :repository) }

  it_behaves_like 'can collect git garbage' do
    let(:resource) { project }
    let(:statistics_service_klass) { Projects::UpdateStatisticsService }
    let(:statistics_keys) { [:repository_size, :lfs_objects_size] }
    let(:expected_default_lease) { "projects:#{resource.id}" }
  end

  context 'when is able to get the lease' do
    let(:params) { [project.id] }

    subject { described_class.new }

    before do
      allow(subject).to receive(:get_lease_uuid).and_return(false)
      allow(subject).to receive(:find_resource).and_return(project)
      allow(subject).to receive(:try_obtain_lease).and_return(SecureRandom.uuid)
    end

    context 'when the repository has joined a pool' do
      let!(:pool) { create(:pool_repository, :ready) }
      let(:project) { pool.source_project }

      it 'ensures the repositories are linked' do
        expect(project.pool_repository).to receive(:link_repository).once

        subject.perform(*params)
      end
    end

    context 'LFS object garbage collection' do
      let_it_be(:lfs_reference) { create(:lfs_objects_project, project: project) }

      let(:lfs_object) { lfs_reference.lfs_object }

      before do
        stub_lfs_setting(enabled: true)
      end

      it 'cleans up unreferenced LFS objects' do
        expect_next_instance_of(Gitlab::Cleanup::OrphanLfsFileReferences) do |svc|
          expect(svc.project).to eq(project)
          expect(svc.dry_run).to be_falsy
          expect(svc).to receive(:run!).and_call_original
        end

        subject.perform(*params)

        expect(project.lfs_objects.reload).not_to include(lfs_object)
      end

      it 'catches and logs exceptions' do
        allow_next_instance_of(Gitlab::Cleanup::OrphanLfsFileReferences) do |svc|
          allow(svg).to receive(:run!).and_raise(/Failed/)
        end

        expect(Gitlab::GitLogger).to receive(:warn)
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception)

        subject.perform(*params)
      end

      it 'does nothing if the database is read-only' do
        allow(Gitlab::Database.main).to receive(:read_only?) { true }
        expect(Gitlab::Cleanup::OrphanLfsFileReferences).not_to receive(:new)

        subject.perform(*params)

        expect(project.lfs_objects.reload).to include(lfs_object)
      end
    end
  end
end
