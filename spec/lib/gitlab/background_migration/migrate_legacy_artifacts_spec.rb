# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateLegacyArtifacts, schema: 20210210093901 do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:jobs) { table(:ci_builds) }
  let(:job_artifacts) { table(:ci_job_artifacts) }

  subject { described_class.new.perform(*range) }

  context 'when a pipeline exists' do
    let!(:namespace) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
    let!(:project) { projects.create!(name: 'gitlab', path: 'gitlab-ce', namespace_id: namespace.id) }
    let!(:pipeline) { pipelines.create!(project_id: project.id, ref: 'master', sha: 'adf43c3a') }

    context 'when a legacy artifacts exists' do
      let(:artifacts_expire_at) { 1.day.since.to_s }
      let(:file_store) { ::ObjectStorage::Store::REMOTE }

      let!(:job) do
        jobs.create!(
          commit_id: pipeline.id,
          project_id: project.id,
          status: :success,
          **artifacts_archive_attributes,
          **artifacts_metadata_attributes)
      end

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

      it 'has legacy artifacts' do
        expect(jobs.pluck('artifacts_file, artifacts_file_store, artifacts_size, artifacts_expire_at')).to eq([artifacts_archive_attributes.values])
        expect(jobs.pluck('artifacts_metadata, artifacts_metadata_store')).to eq([artifacts_metadata_attributes.values])
      end

      it 'does not have new artifacts yet' do
        expect(job_artifacts.count).to be_zero
      end

      context 'when the record exists inside of the range of a background migration' do
        let(:range) { [job.id, job.id] }

        it 'migrates a legacy artifact to ci_job_artifacts table' do
          expect { subject }.to change { job_artifacts.count }.by(2)

          expect(job_artifacts.order(:id).pluck('project_id, job_id, file_type, file_store, size, expire_at, file, file_sha256, file_location'))
            .to eq([[project.id,
                     job.id,
                     described_class::ARCHIVE_FILE_TYPE,
                     file_store,
                     artifacts_archive_attributes[:artifacts_size],
                     artifacts_expire_at,
                     'archive.zip',
                     nil,
                     described_class::LEGACY_PATH_FILE_LOCATION],
                    [project.id,
                     job.id,
                     described_class::METADATA_FILE_TYPE,
                     file_store,
                     nil,
                     artifacts_expire_at,
                     'metadata.gz',
                     nil,
                     described_class::LEGACY_PATH_FILE_LOCATION]])

          expect(jobs.pluck('artifacts_file, artifacts_file_store, artifacts_size, artifacts_expire_at')).to eq([[nil, nil, nil, artifacts_expire_at]])
          expect(jobs.pluck('artifacts_metadata, artifacts_metadata_store')).to eq([[nil, nil]])
        end

        context 'when file_store is nil' do
          let(:file_store) { nil }

          it 'has nullified file_store in all legacy artifacts' do
            expect(jobs.pluck('artifacts_file_store, artifacts_metadata_store')).to eq([[nil, nil]])
          end

          it 'fills file_store by the value of local file store' do
            subject

            expect(job_artifacts.pluck('file_store')).to all(eq(::ObjectStorage::Store::LOCAL))
          end
        end

        context 'when new artifacts has already existed' do
          context 'when only archive.zip existed' do
            before do
              job_artifacts.create!(project_id: project.id, job_id: job.id, file_type: described_class::ARCHIVE_FILE_TYPE, size: 999, file: 'archive.zip')
            end

            it 'had archive.zip already' do
              expect(job_artifacts.exists?(job_id: job.id, file_type: described_class::ARCHIVE_FILE_TYPE)).to be_truthy
            end

            it 'migrates metadata' do
              expect { subject }.to change { job_artifacts.count }.by(1)

              expect(job_artifacts.exists?(job_id: job.id, file_type: described_class::METADATA_FILE_TYPE)).to be_truthy
            end
          end

          context 'when both archive and metadata existed' do
            before do
              job_artifacts.create!(project_id: project.id, job_id: job.id, file_type: described_class::ARCHIVE_FILE_TYPE, size: 999, file: 'archive.zip')
              job_artifacts.create!(project_id: project.id, job_id: job.id, file_type: described_class::METADATA_FILE_TYPE, size: 999, file: 'metadata.zip')
            end

            it 'does not migrate' do
              expect { subject }.not_to change { job_artifacts.count }
            end
          end
        end
      end

      context 'when the record exists outside of the range of a background migration' do
        let(:range) { [job.id + 1, job.id + 1] }

        it 'does not migrate' do
          expect { subject }.not_to change { job_artifacts.count }
        end
      end
    end

    context 'when the job does not have legacy artifacts' do
      let!(:job) { jobs.create!(commit_id: pipeline.id, project_id: project.id, status: :success) }

      it 'does not have the legacy artifacts in database' do
        expect(jobs.count).to eq(1)
        expect(jobs.pluck('artifacts_file, artifacts_file_store, artifacts_size, artifacts_expire_at')).to eq([[nil, nil, nil, nil]])
        expect(jobs.pluck('artifacts_metadata, artifacts_metadata_store')).to eq([[nil, nil]])
      end

      context 'when the record exists inside of the range of a background migration' do
        let(:range) { [job.id, job.id] }

        it 'does not migrate' do
          expect { subject }.not_to change { job_artifacts.count }
        end
      end
    end
  end
end
