# frozen_string_literal: true

require 'fast_spec_helper'
require 'fileutils'
require_relative '../../../spec/contracts/consumer/scripts/upload_contracts_to_gcs'

RSpec.describe GcsContractUploader, feature_category: :tooling do
  let(:base_env) do
    {
      'GCS_BUCKET' => 'gitlab-rails-consumer-contracts',
      'RAILS_CONSUMER_CONTRACT_GCS_BUCKET_KEY' => '/path/to/key.json',
      'GITLAB_VERSION' => '18.0'
    }
  end

  let(:contracts_dir)    { Dir.mktmpdir }
  let(:env)              { base_env }
  let(:uploader)         { described_class.new(env: env, contracts_dir: contracts_dir) }

  # rubocop:disable RSpec/VerifiedDoubles -- fog-google is an external gem; its interface is not available for verification
  let(:fake_storage)     { double('Fog::Google::Storage') }
  let(:fake_files)       { double('Fog::Google::StorageJSON::Files') }
  let(:fake_directory)   { double('Fog::Google::StorageJSON::Directory', files: fake_files) }
  let(:fake_directories) { double('Fog::Google::StorageJSON::Directories') }
  # rubocop:enable RSpec/VerifiedDoubles

  after do
    FileUtils.remove_entry(contracts_dir)
  end

  before do
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/path/to/key.json').and_return(true)
    allow(Fog::Google::Storage).to receive(:new).and_return(fake_storage)
    allow(fake_storage).to receive(:directories).and_return(fake_directories)
    allow(fake_directories).to receive(:new).with(key: 'gitlab-rails-consumer-contracts').and_return(fake_directory)
    allow(fake_files).to receive(:create)
  end

  # Creates a contract JSON file nested under a service subdirectory,
  # mirroring the layout produced by pact-ruby.
  # Directory names and GCS slugs use underscores (e.g. 'artifact_registry');
  # only filenames use hyphens (e.g. 'gitlab-rails-artifact-registry-...').
  #   <contracts_dir>/<service_dir>/<contract-filename>.json
  def create_contract(service_dir, filename)
    path = File.join(contracts_dir, service_dir, filename)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, '{}')
    path
  end

  # -- Validation ------------------------------------------------------------

  describe 'environment validation' do
    context 'when GCS_BUCKET is missing' do
      let(:env) { base_env.merge('GCS_BUCKET' => nil) }

      it 'raises an error' do
        expect { uploader.upload! }.to raise_error(ArgumentError, /GCS_BUCKET/)
      end
    end

    context 'when RAILS_CONSUMER_CONTRACT_GCS_BUCKET_KEY is missing' do
      let(:env) { base_env.merge('RAILS_CONSUMER_CONTRACT_GCS_BUCKET_KEY' => nil) }

      it 'raises an error' do
        expect { uploader.upload! }.to raise_error(ArgumentError, /RAILS_CONSUMER_CONTRACT_GCS_BUCKET_KEY/)
      end
    end
  end

  # -- Version resolution ----------------------------------------------------

  describe 'GitLab version resolution' do
    before do
      create_contract('artifact_registry', 'gitlab-rails-artifact-registry-repositories-get.json')
    end

    context 'when GITLAB_VERSION env var is set' do
      it 'uses the env var value in the object path' do
        expect(fake_files).to receive(:create).with(hash_including(key: include('18.0')))

        uploader.upload!
      end
    end

    context 'when GITLAB_VERSION is not set and CI_COMMIT_REF_NAME is a valid stable branch' do
      let(:env) { base_env.merge('GITLAB_VERSION' => nil, 'CI_COMMIT_REF_NAME' => '18-0-stable-ee') }

      it 'extracts the version from the branch name' do
        expect(fake_files).to receive(:create).with(hash_including(key: include('18.0')))

        uploader.upload!
      end
    end

    context 'when GITLAB_VERSION is not set and CI_COMMIT_REF_NAME is a multi-digit minor version' do
      let(:env) { base_env.merge('GITLAB_VERSION' => nil, 'CI_COMMIT_REF_NAME' => '17-11-stable-ee') }

      it 'extracts the version correctly' do
        expect(fake_files).to receive(:create).with(hash_including(key: include('17.11')))

        uploader.upload!
      end
    end

    context 'when neither GITLAB_VERSION nor a valid CI_COMMIT_REF_NAME is available' do
      let(:env) { base_env.merge('GITLAB_VERSION' => nil, 'CI_COMMIT_REF_NAME' => 'master') }

      it 'raises a descriptive error' do
        expect { uploader.upload! }.to raise_error(/Cannot determine GitLab version/)
      end
    end

    context 'when both GITLAB_VERSION and CI_COMMIT_REF_NAME are set' do
      let(:env) { base_env.merge('GITLAB_VERSION' => '18.0', 'CI_COMMIT_REF_NAME' => '17-11-stable-ee') }

      it 'prefers GITLAB_VERSION' do
        expect(fake_files).to receive(:create).with(hash_including(key: include('18.0')))

        uploader.upload!
      end
    end
  end

  # -- Service slug discovery ------------------------------------------------

  describe 'service slug discovery' do
    context 'when the contracts directory does not exist' do
      let(:uploader) { described_class.new(env: env, contracts_dir: '/nonexistent/path') }

      it 'raises an error' do
        expect { uploader.upload! }.to raise_error(/Contracts directory not found/)
      end
    end

    context 'when there are no subdirectories' do
      it 'raises an error' do
        expect { uploader.upload! }.to raise_error(/No service subdirectories found/)
      end
    end

    context 'when a service subdirectory contains no JSON files' do
      before do
        FileUtils.mkdir_p(File.join(contracts_dir, 'artifact_registry'))
      end

      it 'warns and skips that service without raising' do
        expect { uploader.upload! }.to output(/WARNING.*artifact_registry.*skipping/).to_stderr
        expect { uploader.upload! }.not_to raise_error
      end
    end

    context 'when multiple service subdirectories exist' do
      before do
        create_contract('artifact_registry', 'gitlab-rails-artifact-registry-repositories-get.json')
        create_contract('package_registry', 'gitlab-rails-package-registry-packages-get.json')
      end

      it 'uploads contracts for all discovered services' do
        expect(fake_files).to receive(:create).with(hash_including(key: start_with('artifact_registry/18.0/')))
        expect(fake_files).to receive(:create).with(hash_including(key: start_with('package_registry/18.0/')))

        uploader.upload!
      end
    end
  end

  # -- GCS client construction -----------------------------------------------

  describe 'GCS client construction' do
    before do
      create_contract('artifact_registry', 'gitlab-rails-artifact-registry-repositories-get.json')
    end

    context 'when RAILS_CONSUMER_CONTRACT_GCS_BUCKET_KEY is a file path' do
      it 'initialises Fog with google_json_key_location' do
        expect(Fog::Google::Storage).to receive(:new).with(
          google_project: 'gitlab-rails-consumer-contracts',
          google_json_key_location: '/path/to/key.json'
        ).and_return(fake_storage)

        uploader.upload!
      end
    end

    context 'when RAILS_CONSUMER_CONTRACT_GCS_BUCKET_KEY is a JSON string' do
      let(:json_string) { '{"type":"service_account"}' }
      let(:env) { base_env.merge('RAILS_CONSUMER_CONTRACT_GCS_BUCKET_KEY' => json_string) }

      before do
        allow(File).to receive(:exist?).with(json_string).and_return(false)
      end

      it 'initialises Fog with google_json_key_string' do
        expect(Fog::Google::Storage).to receive(:new).with(
          google_project: 'gitlab-rails-consumer-contracts',
          google_json_key_string: json_string
        ).and_return(fake_storage)

        uploader.upload!
      end
    end
  end

  # -- Upload ----------------------------------------------------------------

  describe 'contract upload' do
    let(:object_path) { 'artifact_registry/18.0/gitlab-rails-artifact-registry-repositories-get.json' }

    before do
      create_contract('artifact_registry', 'gitlab-rails-artifact-registry-repositories-get.json')
    end

    it 'calls files.create with the correct key and content' do
      expect(fake_files).to receive(:create).with(key: object_path, body: '{}')

      uploader.upload!
    end

    context 'when files.create raises an error' do
      before do
        allow(fake_files).to receive(:create).and_raise(StandardError, 'network error')
      end

      it 'raises an error reporting the failure count' do
        expect { uploader.upload! }.to raise_error(/1 contract\(s\) failed to upload/)
      end
    end
  end
end
