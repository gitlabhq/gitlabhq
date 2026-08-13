# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::OrphanLfsFileReferences, feature_category: :source_code_management do
  include ProjectForksHelper

  let(:null_logger) { Logger.new('/dev/null') }
  let(:project) { create(:project, :repository, lfs_enabled: true) }
  let(:lfs_object) { create(:lfs_object) }

  let!(:invalid_reference) { create(:lfs_objects_project, project: project, lfs_object: lfs_object) }

  subject(:service) { described_class.new(project, logger: null_logger, dry_run: dry_run) }

  before do
    allow(null_logger).to receive(:info)

    allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)

    oid = project.repository.gitaly_blob_client.get_all_lfs_pointers.first.lfs_oid
    lfs_object2 = create(:lfs_object, oid: oid)
    create(:lfs_objects_project, project: project, lfs_object: lfs_object2)
  end

  context 'dry run' do
    let(:dry_run) { true }

    context 'when orphan OIDs span multiple slices' do
      let(:oid_batch_size) { 1 }
      let(:additional_lfs_object) { create(:lfs_object) }

      let!(:additional_reference) do
        create(:lfs_objects_project, project: project, lfs_object: additional_lfs_object)
      end

      before do
        stub_const("#{described_class}::OID_BATCH_SIZE", oid_batch_size)
      end

      it 'logs one aggregate count and does not refresh the cache', :aggregate_failures do
        expect(ProjectCacheWorker).not_to receive(:perform_async)
        expect(null_logger).to receive(:info).with('[DRY RUN] Found invalid references: 2').once

        service.run!

        expect(project.lfs_objects_projects.count).to eq(3)
      end
    end

    it 'prints messages and does not delete references' do
      expect(null_logger).to receive(:info).with("[DRY RUN] Looking for orphan LFS files for project #{project.name_with_namespace}")
      expect(null_logger).to receive(:info).with("[DRY RUN] Found invalid references: 1")

      expect { service.run! }.not_to change { project.lfs_objects.count }
    end

    it 'logs zero when all linked objects are reachable', :aggregate_failures do
      allow(project).to receive(:lfs_objects_oids).and_return([])
      expect(ProjectCacheWorker).not_to receive(:perform_async)
      expect(null_logger).to receive(:info).with('[DRY RUN] Found invalid references: 0').once

      expect { service.run! }.not_to change { project.lfs_objects_projects.count }
    end
  end

  context 'regular run' do
    let(:dry_run) { false }

    it 'prints messages and deletes invalid reference' do
      expect(null_logger).to receive(:info).with("Looking for orphan LFS files for project #{project.name_with_namespace}")
      expect(null_logger).to receive(:info).with("Removed invalid references: 1")
      expect(ProjectCacheWorker).to receive(:perform_async).with(project.id, [], %w[lfs_objects_size])
      expect(service).to receive(:remove_orphan_references).and_call_original

      expect { service.run! }.to change { project.lfs_objects.count }.from(2).to(1)

      expect(LfsObjectsProject.exists?(invalid_reference.id)).to be_falsey
    end

    context 'with multiple orphan OID slices' do
      let(:oid_batch_size) { 2 }
      let(:additional_lfs_objects) { create_list(:lfs_object, 2) }
      let(:orphan_oids) { [lfs_object.oid, *additional_lfs_objects.map(&:oid)] }

      let!(:additional_references) do
        additional_lfs_objects.map do |additional_lfs_object|
          create(:lfs_objects_project, project: project, lfs_object: additional_lfs_object)
        end
      end

      before do
        stub_const("#{described_class}::OID_BATCH_SIZE", oid_batch_size)
        allow(project).to receive(:lfs_objects_oids).and_return(orphan_oids)
      end

      it 'queries LFS objects once per bounded OID slice', :aggregate_failures do
        expect(LfsObject).to receive(:for_oids).with(orphan_oids.first(oid_batch_size)).once.and_call_original
        expect(LfsObject).to receive(:for_oids).with(orphan_oids.drop(oid_batch_size)).once.and_call_original

        service.run!
      end

      it 'deletes references across slices and refreshes the cache once', :aggregate_failures do
        expect(ProjectCacheWorker).to receive(:perform_async).with(project.id, [], %w[lfs_objects_size]).once
        expect(null_logger).to receive(:info).with('Removed invalid references: 3').once

        service.run!

        expect(project.lfs_objects_projects.count).to eq(1)
      end
    end

    context 'when LIMIT is smaller than the number of orphan references' do
      let(:additional_lfs_object) { create(:lfs_object) }

      let!(:additional_reference) do
        create(:lfs_objects_project, project: project, lfs_object: additional_lfs_object)
      end

      before do
        stub_env('LIMIT', '1')
      end

      it 'uses LIMIT as the deletion batch size rather than a total limit', :aggregate_failures do
        expect(null_logger).to receive(:info).with('Removed invalid references: 2').once

        service.run!

        expect(project.lfs_objects_projects.count).to eq(1)
      end
    end

    context 'when an OID slice does not resolve to an LFS object' do
      let(:oid_batch_size) { 1 }
      let(:missing_oid) { 'a' * 64 }

      before do
        stub_const("#{described_class}::OID_BATCH_SIZE", oid_batch_size)
        allow(project).to receive(:lfs_objects_oids).and_return([missing_oid, lfs_object.oid])
      end

      it 'continues with subsequent slices', :aggregate_failures do
        expect(ProjectCacheWorker).to receive(:perform_async).with(project.id, [], %w[lfs_objects_size]).once
        expect(null_logger).to receive(:info).with('Removed invalid references: 1').once

        service.run!

        expect(LfsObjectsProject.exists?(invalid_reference.id)).to be(false)
      end
    end

    it 'refreshes the cache when all linked objects are reachable', :aggregate_failures do
      allow(project).to receive(:lfs_objects_oids).and_return([])
      expect(ProjectCacheWorker).to receive(:perform_async).with(project.id, [], %w[lfs_objects_size]).once
      expect(null_logger).to receive(:info).with('Removed invalid references: 0').once

      expect { service.run! }.not_to change { project.lfs_objects_projects.count }
    end

    it 'does nothing if the project has no LFS objects', :aggregate_failures do
      expect(null_logger).to receive(:info).with(/Looking for orphan LFS files/)
      expect(null_logger).to receive(:info).with(/Nothing to do/)

      LfsObjectsProject.where(project: project).delete_all

      expect(service).not_to receive(:remove_orphan_references)
      expect(ProjectCacheWorker).not_to receive(:perform_async)

      service.run!
    end

    context 'LFS object is in design repository' do
      before do
        expect(project.design_repository).to receive(:exists?).and_return(true)

        stub_lfs_pointers(project.design_repository, lfs_object.oid)
      end

      it 'is not removed', :aggregate_failures do
        expect(ProjectCacheWorker).to receive(:perform_async).with(project.id, [], %w[lfs_objects_size])

        expect { service.run! }.not_to change { project.lfs_objects.count }
      end
    end

    context 'LFS object is in wiki repository' do
      before do
        expect(project.wiki.repository).to receive(:exists?).and_return(true)

        stub_lfs_pointers(project.wiki.repository, lfs_object.oid)
      end

      it 'is not removed', :aggregate_failures do
        expect(ProjectCacheWorker).to receive(:perform_async).with(project.id, [], %w[lfs_objects_size])

        expect { service.run! }.not_to change { project.lfs_objects.count }
      end
    end
  end

  context 'LFS for project snippets' do
    let(:snippet) { create(:project_snippet) }

    it 'is disabled' do
      # Support project snippets here before enabling LFS for them
      expect(snippet.repository.lfs_enabled?).to be_falsy
    end
  end

  def stub_lfs_pointers(repo, *oids)
    expect(repo.gitaly_blob_client)
      .to receive(:get_all_lfs_pointers)
      .and_return(oids.map { |oid| instance_double(Gitlab::Git::Blob, lfs_oid: oid) })
  end
end
