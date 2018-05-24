require 'spec_helper'

describe Gitlab::BackgroundMigration::MigrateLegacyArtifacts, :migration, schema: 20180427161409 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:jobs) { table(:ci_builds) }
  let(:job_artifacts) { table(:ci_job_artifacts) }

  context 'when a pipeline exists' do
    let(:pipeline_id) { 1 }
    let(:project_id) { 123 }

    before do
      namespaces.create!(id: 1, name: 'gitlab', path: 'gitlab-org')
      projects.create!(id: project_id, name: 'gitlab', path: 'gitlab-ce', namespace_id: 1)
      pipelines.create!(id: pipeline_id, project_id: project_id, ref: 'master', sha: 'adf43c3a')
    end

    context 'when a legacy artifacts exists' do
      let(:artifacts_expire_at) { 1.day.since.to_s }
      let(:file_store) { 2 }
      let(:job_id) { 1 }
      let(:file_type_archive) { 1 }
      let(:file_type_metadata) { 2 }
      let(:file_location_legacy_path) { 1 }

      let(:artifacts_archive_attributes) do
        {
          artifacts_file: 'archive.zip',
          artifacts_file_store: file_store,
          artifacts_size: 123,
          artifacts_expire_at: artifacts_expire_at
        }
      end

      let(:artifacts_metadata_attributes) do
        {
          artifacts_metadata: 'metadata.gz',
          artifacts_metadata_store: file_store
        }
      end

      before do
        jobs.create!(id: job_id, commit_id: pipeline_id, project_id: project_id, status: :success, **artifacts_archive_attributes, **artifacts_metadata_attributes)
      end

      it 'has legacy artifacts' do
        expect(jobs.pluck('artifacts_file, artifacts_file_store, artifacts_size, artifacts_expire_at')).to eq([artifacts_archive_attributes.values])
        expect(jobs.pluck('artifacts_metadata, artifacts_metadata_store')).to eq([artifacts_metadata_attributes.values])
      end

      it 'does not have new artifacts yet' do
        expect(job_artifacts.count).to be_zero
      end

      context 'when the record exists inside of the range of a background migration' do
        let(:range) { [1, 1] }

        it 'migrates' do
          described_class.new.perform(*range)

          expect(job_artifacts.order(:id).pluck('project_id, job_id, file_type, file_store, size, expire_at, file, file_sha256, file_location'))
            .to eq([[project_id, job_id, file_type_archive,  file_store, artifacts_archive_attributes[:artifacts_size], artifacts_expire_at, 'archive.zip', nil, file_location_legacy_path],
                    [project_id, job_id, file_type_metadata, file_store,                                           nil, artifacts_expire_at, 'metadata.gz', nil, file_location_legacy_path]])

          expect(jobs.pluck('artifacts_file, artifacts_file_store, artifacts_size, artifacts_expire_at')).to eq([[nil, nil, nil, artifacts_expire_at]])
          expect(jobs.pluck('artifacts_metadata, artifacts_metadata_store')).to eq([[nil, nil]])
        end

        context 'when file_store is nil' do
          let(:file_store) { nil }

          it 'fills file_store by 1 (ObjectStorage::Store::LOCAL)' do
            expect(jobs.pluck('artifacts_file_store, artifacts_metadata_store')).to eq([[nil, nil]])

            described_class.new.perform(*range)
  
            expect(job_artifacts.pluck('file_store')).to eq([1, 1])
          end
        end

        context 'when new artifacts has already existed' do
          before do
            job_artifacts.create!(id: 1, project_id: project_id, job_id: job_id, file_type: 1, size: 123, file: 'archive.zip')
          end

          it 'does not migrate' do
            described_class.new.perform(*range)
  
            expect(job_artifacts.pluck('id')).to eq([1])
          end
        end
      end

      context 'when the record exists outside of the range of a background migration' do
        let(:range) { [2, 2] }

        it 'does not migrate' do
          described_class.new.perform(*range)

          expect(job_artifacts.count).to be_zero
        end
      end
    end

    context 'when legacy artifacts do not exist' do
      before do
        jobs.create!(id: 1, commit_id: pipeline_id, project_id: project_id, status: :success)
      end

      it 'is not found from database' do
        expect(jobs.pluck('artifacts_file, artifacts_file_store, artifacts_size, artifacts_expire_at')).to eq([[nil, nil, nil, nil]])
        expect(jobs.pluck('artifacts_metadata, artifacts_metadata_store')).to eq([[nil, nil]])
      end

      context 'when the record exists inside of the range of a background migration' do
        let(:range) { [1, 1] }

        it 'does not migrate' do
          described_class.new.perform(*range)

          expect(job_artifacts.count).to be_zero
        end
      end
    end
  end
end
