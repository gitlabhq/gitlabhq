# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobArtifacts::CreateService, :clean_gitlab_redis_shared_state, feature_category: :job_artifacts do
  include WorkhorseHelpers
  include Gitlab::Utils::Gzip

  let_it_be(:project) { create(:project) }

  let(:service) { described_class.new(job) }
  let(:job) { create(:ci_build, project: project) }

  describe '#authorize', :aggregate_failures do
    let(:artifact_type) { 'archive' }
    let(:filesize) { nil }

    subject(:authorize) { service.authorize(artifact_type: artifact_type, filesize: filesize) }

    shared_examples_for 'handling lsif artifact' do
      context 'when artifact is lsif' do
        let(:artifact_type) { 'lsif' }
        let(:max_artifact_size) { 200.megabytes.to_i }

        before do
          allow(Ci::JobArtifact)
            .to receive(:max_artifact_size)
            .with(type: artifact_type, project: project)
            .and_return(max_artifact_size)
        end

        it 'includes ProcessLsif in the headers' do
          expect(authorize[:headers][:ProcessLsif]).to eq(true)
        end

        it 'returns 200MB in bytes as maximum size' do
          expect(authorize[:headers][:MaximumSize]).to eq(200.megabytes.to_i)
        end
      end
    end

    shared_examples_for 'validating requirements' do
      context 'when filesize is specified' do
        let(:max_artifact_size) { 10 }

        before do
          allow(Ci::JobArtifact)
            .to receive(:max_artifact_size)
            .with(type: artifact_type, project: project)
            .and_return(max_artifact_size)
        end

        context 'and filesize exceeds the limit' do
          let(:filesize) { max_artifact_size + 1 }

          it 'returns error' do
            expect(authorize[:status]).to eq(:error)
          end
        end

        context 'and filesize does not exceed the limit' do
          let(:filesize) { max_artifact_size - 1 }

          it 'returns success' do
            expect(authorize[:status]).to eq(:success)
          end
        end
      end
    end

    shared_examples_for 'uploading to temp location' do |store_type|
      # We are not testing the entire headers here because this is fully tested
      # in workhorse_authorize's spec. We just want to confirm that it indeed used the temp path
      # by checking some indicators in the headers returned.
      if store_type == :object_storage
        it 'includes the authorize headers' do
          expect(authorize[:status]).to eq(:success)
          expect(authorize[:headers][:RemoteObject][:StoreURL]).to include(ObjectStorage::TMP_UPLOAD_PATH)
        end
      else
        it 'includes the authorize headers' do
          expect(authorize[:status]).to eq(:success)
          expect(authorize[:headers][:TempPath]).to include(ObjectStorage::TMP_UPLOAD_PATH)
        end
      end

      it_behaves_like 'handling lsif artifact'
      it_behaves_like 'validating requirements'
    end

    context 'when object storage is enabled' do
      context 'and direct upload is enabled' do
        let(:final_store_path) { '12/34/abc-123' }

        before do
          stub_artifacts_object_storage(JobArtifactUploader, direct_upload: true)

          allow(JobArtifactUploader)
            .to receive(:generate_final_store_path)
            .with(root_hash: project.id)
            .and_return(final_store_path)
        end

        it 'includes the authorize headers' do
          expect(authorize[:status]).to eq(:success)

          expect(authorize[:headers][:RemoteObject][:ID]).to eq(final_store_path)

          # We are not testing the entire headers here because this is fully tested
          # in workhorse_authorize's spec. We just want to confirm that it indeed used the final path
          # by checking some indicators in the headers returned.
          expect(authorize[:headers][:RemoteObject][:StoreURL])
            .to include(final_store_path)

          # We have to ensure to tell Workhorse to skip deleting the file after upload
          # because we are uploading the file to its final location
          expect(authorize[:headers][:RemoteObject][:SkipDelete]).to eq(true)
        end

        it_behaves_like 'handling lsif artifact'
        it_behaves_like 'validating requirements'
      end

      context 'and direct upload is disabled' do
        before do
          stub_artifacts_object_storage(JobArtifactUploader, direct_upload: false)
        end

        it_behaves_like 'uploading to temp location', :local_storage
      end
    end

    context 'when object storage is disabled' do
      it_behaves_like 'uploading to temp location', :local_storage
    end
  end

  describe '#execute' do
    let(:artifacts_sha256) { '0' * 64 }
    let(:metadata_file) { nil }

    let(:params) do
      {
        'artifact_type' => 'archive',
        'artifact_format' => 'zip'
      }.with_indifferent_access
    end

    subject(:execute) { service.execute(artifacts_file, params, metadata_file: metadata_file) }

    context 'when artifacts have none access setting' do
      let(:artifacts_file) do
        file_to_upload('spec/fixtures/ci_build_artifacts.zip', sha256: artifacts_sha256)
      end

      let(:access_job) { create(:ci_build, :no_access_artifacts, project: project) }
      let(:access_service) { described_class.new(access_job) }

      it 'sets accessibility to none' do
        access_service.execute(artifacts_file, params, metadata_file: metadata_file)

        expect(access_job.job_artifacts).not_to be_empty
        expect(access_job.job_artifacts).to all be_none_accessibility
      end
    end

    shared_examples_for 'handling accessibility' do
      shared_examples 'public accessibility' do
        it 'sets accessibility to public level' do
          subject

          expect(job.job_artifacts).not_to be_empty
          expect(job.job_artifacts).to all be_public_accessibility
        end
      end

      shared_examples 'private accessibility' do
        it 'sets accessibility to private level' do
          subject

          expect(job.job_artifacts).not_to be_empty
          expect(job.job_artifacts).to all be_private_accessibility
        end
      end

      context 'when accessibility passed as invalid value' do
        before do
          params.merge!('accessibility' => 'foo')
        end

        it 'fails with argument error' do
          expect { execute }.to raise_error(ArgumentError, "'foo' is not a valid accessibility")
        end
      end
    end

    shared_examples_for 'handling metadata file' do
      context 'when metadata file is also uploaded' do
        let(:metadata_file) do
          file_to_upload('spec/fixtures/ci_build_artifacts_metadata.gz', sha256: artifacts_sha256)
        end

        before do
          stub_application_setting(default_artifacts_expire_in: '1 day')
        end

        it 'creates a new metadata job artifact' do
          expect { execute }.to change { Ci::JobArtifact.where(file_type: :metadata).count }.by(1)

          new_artifact = job.job_artifacts.last
          expect(new_artifact.project).to eq(job.project)
          expect(new_artifact.file).to be_present
          expect(new_artifact.file_type).to eq('metadata')
          expect(new_artifact.file_format).to eq('gzip')
          expect(new_artifact.file_sha256).to eq(artifacts_sha256)
          expect(new_artifact.locked).to eq(job.pipeline.locked)
        end

        it 'logs the created artifact and metadata' do
          expect(Gitlab::Ci::Artifacts::Logger)
            .to receive(:log_created)
            .with(an_instance_of(Ci::JobArtifact)).twice

          subject
        end

        it_behaves_like 'handling accessibility'

        it 'sets expiration date according to application settings' do
          expected_expire_at = 1.day.from_now

          expect(execute).to match(a_hash_including(status: :success, artifact: anything))
          archive_artifact, metadata_artifact = job.job_artifacts.last(2)

          expect(job.artifacts_expire_at).to be_within(1.minute).of(expected_expire_at)
          expect(archive_artifact.expire_at).to be_within(1.minute).of(expected_expire_at)
          expect(metadata_artifact.expire_at).to be_within(1.minute).of(expected_expire_at)
        end

        context 'when expire_in params is set to a specific value' do
          before do
            params.merge!('expire_in' => '2 hours')
          end

          it 'sets expiration date according to the parameter' do
            expected_expire_at = 2.hours.from_now

            expect(execute).to match(a_hash_including(status: :success, artifact: anything))
            archive_artifact, metadata_artifact = job.job_artifacts.last(2)

            expect(job.artifacts_expire_at).to be_within(1.minute).of(expected_expire_at)
            expect(archive_artifact.expire_at).to be_within(1.minute).of(expected_expire_at)
            expect(metadata_artifact.expire_at).to be_within(1.minute).of(expected_expire_at)
          end
        end

        context 'when expire_in params is set to `never`' do
          before do
            params.merge!('expire_in' => 'never')
          end

          it 'sets expiration date according to the parameter' do
            expected_expire_at = nil

            expect(execute).to be_truthy
            archive_artifact, metadata_artifact = job.job_artifacts.last(2)

            expect(job.artifacts_expire_at).to eq(expected_expire_at)
            expect(archive_artifact.expire_at).to eq(expected_expire_at)
            expect(metadata_artifact.expire_at).to eq(expected_expire_at)
          end
        end
      end
    end

    shared_examples_for 'handling dotenv' do |storage_type|
      context 'when artifact type is dotenv' do
        let(:params) do
          {
            'artifact_type' => 'dotenv',
            'artifact_format' => 'gzip'
          }.with_indifferent_access
        end

        if storage_type == :object_storage
          let(:object_body) { File.read('spec/fixtures/build.env.gz') }
          let(:upload_filename) { 'build.env.gz' }

          before do
            stub_request(:get, %r{s3.amazonaws.com/#{remote_path}})
              .to_return(status: 200, body: File.read('spec/fixtures/build.env.gz'))
          end
        else
          let(:artifacts_file) do
            file_to_upload('spec/fixtures/build.env.gz', sha256: artifacts_sha256)
          end
        end

        it 'calls parse service' do
          expect_any_instance_of(Ci::ParseDotenvArtifactService) do |service|
            expect(service).to receive(:execute).once.and_call_original
          end

          expect(execute[:status]).to eq(:success)
          expect(job.job_variables.as_json(only: [:key, :value, :source])).to contain_exactly(
            hash_including('key' => 'KEY1', 'value' => 'VAR1', 'source' => 'dotenv'),
            hash_including('key' => 'KEY2', 'value' => 'VAR2', 'source' => 'dotenv'))
        end
      end
    end

    shared_examples_for 'handling annotations' do |storage_type|
      context 'when artifact type is annotations' do
        let(:params) do
          {
            'artifact_type' => 'annotations',
            'artifact_format' => 'gzip'
          }.with_indifferent_access
        end

        if storage_type == :object_storage
          let(:object_body) { File.read('spec/fixtures/gl-annotations.json.gz') }
          let(:upload_filename) { 'gl-annotations.json.gz' }

          before do
            stub_request(:get, %r{s3.amazonaws.com/#{remote_path}})
              .to_return(status: 200, body: File.read('spec/fixtures/gl-annotations.json.gz'))
          end
        else
          let(:artifacts_file) do
            file_to_upload('spec/fixtures/gl-annotations.json.gz', sha256: artifacts_sha256)
          end
        end

        it 'calls parse service' do
          expect_any_instance_of(Ci::ParseAnnotationsArtifactService) do |service|
            expect(service).to receive(:execute).once.and_call_original
          end

          expect(execute[:status]).to eq(:success)
          expect(job.job_annotations.as_json).to contain_exactly(
            hash_including('name' => 'external_links', 'data' => [
              hash_including('external_link' => hash_including('label' => 'URL 1', 'url' => 'https://url1.example.com/')),
              hash_including('external_link' => hash_including('label' => 'URL 2', 'url' => 'https://url2.example.com/'))
            ])
          )
        end
      end
    end

    shared_examples_for 'handling object storage errors' do
      shared_examples 'rescues object storage error' do |klass, message, expected_message|
        it "handles #{klass}" do
          allow_next_instance_of(JobArtifactUploader) do |uploader|
            allow(uploader).to receive(:store!).and_raise(klass, message)
          end

          expect(Gitlab::ErrorTracking)
            .to receive(:track_exception)
            .and_call_original

          expect(execute).to match(
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

    shared_examples_for 'validating requirements' do
      context 'when filesize is specified' do
        let(:max_artifact_size) { 10 }

        before do
          allow(Ci::JobArtifact)
            .to receive(:max_artifact_size)
            .with(type: 'archive', project: project)
            .and_return(max_artifact_size)

          allow(artifacts_file).to receive(:size).and_return(filesize)
        end

        context 'and filesize exceeds the limit' do
          let(:filesize) { max_artifact_size + 1 }

          it 'returns error' do
            expect(execute[:status]).to eq(:error)
          end
        end

        context 'and filesize does not exceed the limit' do
          let(:filesize) { max_artifact_size - 1 }

          it 'returns success' do
            expect(execute[:status]).to eq(:success)
          end
        end
      end
    end

    shared_examples_for 'handling existing artifact' do
      context 'when job already has an artifact of the same file type' do
        let!(:existing_artifact) do
          create(:ci_job_artifact, params[:artifact_type], file_sha256: existing_sha256, job: job)
        end

        context 'when sha256 of uploading artifact is the same of the existing one' do
          let(:existing_sha256) { artifacts_sha256 }

          it 'ignores the changes' do
            expect { execute }.not_to change { Ci::JobArtifact.count }
            expect(execute).to match(a_hash_including(status: :success))
          end
        end

        context 'when sha256 of uploading artifact is different than the existing one' do
          let(:existing_sha256) { '1' * 64 }

          it 'returns error status' do
            expect(Gitlab::ErrorTracking).to receive(:track_exception).and_call_original

            expect { execute }.not_to change { Ci::JobArtifact.count }
            expect(execute).to match(
              a_hash_including(
                http_status: :bad_request,
                message: 'another artifact of the same type already exists',
                status: :error
              )
            )
          end
        end
      end
    end

    shared_examples_for 'logging artifact' do
      it 'logs the created artifact' do
        expect(Gitlab::Ci::Artifacts::Logger)
          .to receive(:log_created)
          .with(an_instance_of(Ci::JobArtifact))

        execute
      end
    end

    shared_examples_for 'handling uploads' do
      context 'when artifacts file is uploaded' do
        it 'creates a new job artifact' do
          expect { execute }.to change { Ci::JobArtifact.count }.by(1)

          new_artifact = execute[:artifact]
          expect(new_artifact).to eq(job.job_artifacts.last)
          expect(new_artifact.project).to eq(job.project)
          expect(new_artifact.file.filename).to eq(artifacts_file.original_filename)
          expect(new_artifact.file_identifier).to eq(artifacts_file.original_filename)
          expect(new_artifact.file_type).to eq(params['artifact_type'])
          expect(new_artifact.file_format).to eq(params['artifact_format'])
          expect(new_artifact.file_sha256).to eq(artifacts_sha256)
          expect(new_artifact.locked).to eq(job.pipeline.locked)
          expect(new_artifact.size).to eq(artifacts_file.size)

          expect(execute[:status]).to eq(:success)
        end

        it_behaves_like 'handling accessibility'
        it_behaves_like 'handling metadata file'
        it_behaves_like 'handling partitioning'
        it_behaves_like 'logging artifact'
      end
    end

    shared_examples_for 'handling partitioning' do
      context 'with job partitioned' do
        let(:partition_id) { ci_testing_partition_id }
        let(:pipeline) { create(:ci_pipeline, project: project, partition_id: partition_id) }
        let(:job) { create(:ci_build, pipeline: pipeline) }

        it 'sets partition_id on artifacts' do
          expect { execute }.to change { Ci::JobArtifact.count }

          artifacts_partitions = job.job_artifacts.map(&:partition_id).uniq

          expect(artifacts_partitions).to eq([partition_id])
        end
      end
    end

    context 'when object storage and direct upload is enabled' do
      let(:fog_connection) { stub_artifacts_object_storage(JobArtifactUploader, direct_upload: true) }
      let(:remote_path) { File.join(remote_store_path, remote_id) }
      let(:object_body) { File.open('spec/fixtures/ci_build_artifacts.zip') }
      let(:upload_filename) { 'artifacts.zip' }
      let(:object) do
        fog_connection.directories
          .new(key: 'artifacts')
          .files
          .create( # rubocop:disable Rails/SaveBang
            key: remote_path,
            body: object_body
          )
      end

      let(:artifacts_file) do
        fog_to_uploaded_file(
          object,
          filename: upload_filename,
          sha256: artifacts_sha256,
          remote_id: remote_id
        )
      end

      let(:remote_id) { 'generated-remote-id-12345' }
      let(:remote_store_path) { ObjectStorage::TMP_UPLOAD_PATH }

      it_behaves_like 'handling uploads'
      it_behaves_like 'handling dotenv', :object_storage
      it_behaves_like 'handling annotations', :object_storage
      it_behaves_like 'handling object storage errors'
      it_behaves_like 'validating requirements'
    end

    context 'when using local storage' do
      let(:artifacts_file) do
        file_to_upload('spec/fixtures/ci_build_artifacts.zip', sha256: artifacts_sha256)
      end

      it_behaves_like 'handling uploads'
      it_behaves_like 'handling dotenv', :local_storage
      it_behaves_like 'handling annotations', :local_storage
      it_behaves_like 'validating requirements'
    end
  end

  def file_to_upload(path, params = {})
    upload = Tempfile.new('upload')
    FileUtils.copy(path, upload.path)
    # This is a workaround for https://github.com/docker/for-linux/issues/1015
    FileUtils.touch(upload.path)

    UploadedFile.new(upload.path, **params)
  end
end
