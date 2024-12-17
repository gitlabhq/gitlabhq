# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Cleanup::OrphanLfsFileReferences do
  include ProjectForksHelper

  let(:null_logger) { Logger.new('/dev/null') }
  let(:project) { create(:project, :repository, lfs_enabled: true) }
  let(:lfs_object) { create(:lfs_object) }

  let!(:invalid_reference) { create(:lfs_objects_project, project: project, lfs_object: lfs_object) }

  subject(:service) { described_class.new(project, logger: null_logger, dry_run: dry_run) }

  before do
    allow(null_logger).to receive(:info)

    allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)

    # Create a valid reference
    oid = project.repository.gitaly_blob_client.get_all_lfs_pointers.first.lfs_oid
    lfs_object2 = create(:lfs_object, oid: oid)
    create(:lfs_objects_project, project: project, lfs_object: lfs_object2)
  end

  context 'dry run' do
    let(:dry_run) { true }

    it 'prints messages and does not delete references' do
      expect(null_logger).to receive(:info).with("[DRY RUN] Looking for orphan LFS files for project #{project.name_with_namespace}")
      expect(null_logger).to receive(:info).with("[DRY RUN] Found invalid references: 1")

      expect { service.run! }.not_to change { project.lfs_objects.count }
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

    it 'does nothing if the project has no LFS objects' do
      expect(null_logger).to receive(:info).with(/Looking for orphan LFS files/)
      expect(null_logger).to receive(:info).with(/Nothing to do/)

      LfsObjectsProject.where(project: project).delete_all

      expect(service).not_to receive(:remove_orphan_references)

      service.run!
    end

    context 'LFS object is in design repository' do
      before do
        expect(project.design_repository).to receive(:exists?).and_return(true)

        stub_lfs_pointers(project.design_repository, lfs_object.oid)
      end

      it 'is not removed' do
        expect { service.run! }.not_to change { project.lfs_objects.count }
      end
    end

    context 'LFS object is in wiki repository' do
      before do
        expect(project.wiki.repository).to receive(:exists?).and_return(true)

        stub_lfs_pointers(project.wiki.repository, lfs_object.oid)
      end

      it 'is not removed' do
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
      .and_return(oids.map { |oid| double('pointers', lfs_oid: oid) })
  end
end
