# frozen_string_literal: true

require 'spec_helper'

describe Ci::CreateJobArtifactsService do
  let_it_be(:project) { create(:project) }
  let(:service) { described_class.new(project) }
  let(:job) { create(:ci_build, project: project) }
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

    context 'locking' do
      let(:old_job) { create(:ci_build, pipeline: create(:ci_pipeline, project: job.project, ref: job.ref)) }
      let!(:latest_artifact) { create(:ci_job_artifact, job: old_job, locked: true) }
      let!(:other_artifact) { create(:ci_job_artifact, locked: true) }

      it 'locks the new artifact' do
        subject

        expect(Ci::JobArtifact.last).to have_attributes(locked: true)
      end

      it 'unlocks all other artifacts for the same ref' do
        expect { subject }.to change { latest_artifact.reload.locked }.from(true).to(false)
      end

      it 'does not unlock artifacts for other refs' do
        expect { subject }.not_to change { other_artifact.reload.locked }.from(true)
      end
    end

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

          expect(subject).to match(a_hash_including(status: :success))
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

            expect(subject).to match(a_hash_including(status: :success))
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
          expect(subject).to match(a_hash_including(status: :success))
        end
      end

      context 'when sha256 of uploading artifact is different than the existing one' do
        let(:existing_sha256) { '1' * 64 }

        it 'returns error status' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

          expect { subject }.not_to change { Ci::JobArtifact.count }
          expect(subject).to match(
            a_hash_including(http_status: :bad_request,
              message: 'another artifact of the same type already exists',
              status: :error))
        end
      end
    end

    context 'when artifact type is dotenv' do
      let(:artifacts_file) do
        file_to_upload('spec/fixtures/build.env.gz', sha256: artifacts_sha256)
      end

      let(:params) do
        {
          'artifact_type' => 'dotenv',
          'artifact_format' => 'gzip'
        }
      end

      it 'calls parse service' do
        expect_any_instance_of(Ci::ParseDotenvArtifactService) do |service|
          expect(service).to receive(:execute).once.and_call_original
        end

        expect(subject[:status]).to eq(:success)
        expect(job.job_variables.as_json).to contain_exactly(
          hash_including('key' => 'KEY1', 'value' => 'VAR1', 'source' => 'dotenv'),
          hash_including('key' => 'KEY2', 'value' => 'VAR2', 'source' => 'dotenv'))
      end

      context 'when ci_synchronous_artifact_parsing feature flag is disabled' do
        before do
          stub_feature_flags(ci_synchronous_artifact_parsing: false)
        end

        it 'does not call parse service' do
          expect(Ci::ParseDotenvArtifactService).not_to receive(:new)

          expect(subject[:status]).to eq(:success)
        end
      end
    end

    shared_examples 'rescues object storage error' do |klass, message, expected_message|
      it "handles #{klass}" do
        allow_next_instance_of(JobArtifactUploader) do |uploader|
          allow(uploader).to receive(:store!).and_raise(klass, message)
        end

        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception)
          .and_call_original

        expect(subject).to match(
          a_hash_including(
            http_status: :service_unavailable,
            message: expected_message || message,
            status: :error))
      end
    end

    it_behaves_like 'rescues object storage error',
      Errno::EIO, 'some/path', 'Input/output error - some/path'

    it_behaves_like 'rescues object storage error',
      Google::Apis::ServerError, 'Server error'

    it_behaves_like 'rescues object storage error',
      Signet::RemoteServerError, 'The service is currently unavailable'
  end
end
