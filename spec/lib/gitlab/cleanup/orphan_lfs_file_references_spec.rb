# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Cleanup::OrphanLfsFileReferences do
  let(:null_logger) { Logger.new('/dev/null') }
  let(:project) { create(:project, :repository, lfs_enabled: true) }
  let(:lfs_object) { create(:lfs_object) }

  let!(:invalid_reference) { create(:lfs_objects_project, project: project, lfs_object: lfs_object) }

  before do
    allow(null_logger).to receive(:info)

    allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)

    # Create a valid reference
    oid = project.repository.gitaly_blob_client.get_all_lfs_pointers.first.lfs_oid
    lfs_object2 = create(:lfs_object, oid: oid)
    create(:lfs_objects_project, project: project, lfs_object: lfs_object2)
  end

  context 'dry run' do
    it 'prints messages and does not delete references' do
      expect(null_logger).to receive(:info).with("[DRY RUN] Looking for orphan LFS files for project #{project.name_with_namespace}")
      expect(null_logger).to receive(:info).with("[DRY RUN] Found invalid references: 1")

      expect { described_class.new(project, logger: null_logger).run! }
        .not_to change { project.lfs_objects.count }
    end
  end

  context 'regular run' do
    it 'prints messages and deletes invalid reference' do
      expect(null_logger).to receive(:info).with("Looking for orphan LFS files for project #{project.name_with_namespace}")
      expect(null_logger).to receive(:info).with("Removed invalid references: 1")
      expect(ProjectCacheWorker).to receive(:perform_async).with(project.id, [], [:lfs_objects_size])

      expect { described_class.new(project, logger: null_logger, dry_run: false).run! }
        .to change { project.lfs_objects.count }.from(2).to(1)

      expect(LfsObjectsProject.exists?(invalid_reference.id)).to be_falsey
    end
  end
end
