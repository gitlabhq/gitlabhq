require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20180424151928_fill_file_store')

describe FillFileStore, :migration do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:builds) { table(:ci_builds) }
  let(:job_artifacts) { table(:ci_job_artifacts) }
  let(:lfs_objects) { table(:lfs_objects) }
  let(:uploads) { table(:uploads) }

  before do
    namespaces.create!(id: 123, name: 'gitlab1', path: 'gitlab1')
    projects.create!(id: 123, name: 'gitlab1', path: 'gitlab1', namespace_id: 123)
    builds.create!(id: 1)

    ##
    # Create rows that have nullfied `file_store` column
    job_artifacts.create!(project_id: 123, job_id: 1, file_type: 1, file_store: nil)
    lfs_objects.create!(oid: 123, size: 10, file: 'file_name', file_store: nil)
    uploads.create!(size: 10, path: 'path', uploader: 'uploader', mount_point: 'file_name', store: nil)
  end

  it 'correctly migrates nullified file_store/store column' do
    expect(job_artifacts.where(file_store: nil).count).to eq(1)
    expect(lfs_objects.where(file_store: nil).count).to eq(1)
    expect(uploads.where(store: nil).count).to eq(1)

    expect(job_artifacts.where(file_store: 1).count).to eq(0)
    expect(lfs_objects.where(file_store: 1).count).to eq(0)
    expect(uploads.where(store: 1).count).to eq(0)

    migrate!

    expect(job_artifacts.where(file_store: nil).count).to eq(0)
    expect(lfs_objects.where(file_store: nil).count).to eq(0)
    expect(uploads.where(store: nil).count).to eq(0)

    expect(job_artifacts.where(file_store: 1).count).to eq(1)
    expect(lfs_objects.where(file_store: 1).count).to eq(1)
    expect(uploads.where(store: 1).count).to eq(1)
  end
end
