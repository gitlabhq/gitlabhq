# frozen_string_literal: true

require 'spec_helper'

describe Ci::CreateJobArtifactsService do
  let(:service) { described_class.new }
  let(:job) { create(:ci_build) }
  let(:artifacts_sha256) { '0' * 64 }
  let(:metadata_file) { nil }

  let(:artifacts_file) do
    file_to_upload('spec/fixtures/ci_build_artifacts.zip', sha256: artifacts_sha256)
  end

  let(:params) do
    {
      'artifact_type' => 'archive',
      'artifact_format' => 'zip'
    }
  end

  def file_to_upload(path, params = {})
    upload = Tempfile.new('upload')
    FileUtils.copy(path, upload.path)

    UploadedFile.new(upload.path, params)
  end

  describe '#execute' do
    subject { service.execute(job, artifacts_file, params, metadata_file: metadata_file) }

    context 'when artifacts file is uploaded' do
      it 'saves artifact for the given type' do
        expect { subject }.to change { Ci::JobArtifact.count }.by(1)

        new_artifact = job.job_artifacts.last
        expect(new_artifact.project).to eq(job.project)
        expect(new_artifact.file).to be_present
        expect(new_artifact.file_type).to eq(params['artifact_type'])
        expect(new_artifact.file_format).to eq(params['artifact_format'])
        expect(new_artifact.file_sha256).to eq(artifacts_sha256)
      end

      context 'when metadata file is also uploaded' do
        let(:metadata_file) do
          file_to_upload('spec/fixtures/ci_build_artifacts_metadata.gz', sha256: artifacts_sha256)
        end

        before do
          stub_application_setting(default_artifacts_expire_in: '1 day')
        end

        it 'saves metadata artifact' do
          expect { subject }.to change { Ci::JobArtifact.count }.by(2)

          new_artifact = job.job_artifacts.last
          expect(new_artifact.project).to eq(job.project)
          expect(new_artifact.file).to be_present
          expect(new_artifact.file_type).to eq('metadata')
          expect(new_artifact.file_format).to eq('gzip')
          expect(new_artifact.file_sha256).to eq(artifacts_sha256)
        end

        it 'sets expiration date according to application settings' do
          expected_expire_at = 1.day.from_now

          expect(subject).to be_truthy
          archive_artifact, metadata_artifact = job.job_artifacts.last(2)

          expect(job.artifacts_expire_at).to be_within(1.minute).of(expected_expire_at)
          expect(archive_artifact.expire_at).to be_within(1.minute).of(expected_expire_at)
          expect(metadata_artifact.expire_at).to be_within(1.minute).of(expected_expire_at)
        end

        context 'when expire_in params is set' do
          before do
            params.merge!('expire_in' => '2 hours')
          end

          it 'sets expiration date according to the parameter' do
            expected_expire_at = 2.hours.from_now

            expect(subject).to be_truthy
            archive_artifact, metadata_artifact = job.job_artifacts.last(2)

            expect(job.artifacts_expire_at).to be_within(1.minute).of(expected_expire_at)
            expect(archive_artifact.expire_at).to be_within(1.minute).of(expected_expire_at)
            expect(metadata_artifact.expire_at).to be_within(1.minute).of(expected_expire_at)
          end
        end
      end
    end

    context 'when artifacts file already exists' do
      let!(:existing_artifact) do
        create(:ci_job_artifact, :archive, file_sha256: existing_sha256, job: job)
      end

      context 'when sha256 of uploading artifact is the same of the existing one' do
        let(:existing_sha256) { artifacts_sha256 }

        it 'ignores the changes' do
          expect { subject }.not_to change { Ci::JobArtifact.count }
          expect(subject).to be_truthy
        end
      end

      context 'when sha256 of uploading artifact is different than the existing one' do
        let(:existing_sha256) { '1' * 64 }

        it 'returns false and logs the error' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

          expect { subject }.not_to change { Ci::JobArtifact.count }
          expect(subject).to be_falsey
          expect(job.errors[:base]).to contain_exactly('another artifact of the same type already exists')
        end
      end
    end
  end
end
