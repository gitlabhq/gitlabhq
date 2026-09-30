# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Pages::DeploymentUploader, feature_category: :pages do
  let(:pages_deployment) { build_stubbed(:pages_deployment) }
  let(:uploader) { described_class.new(pages_deployment, :file) }

  let(:file) do
    fixture_file_upload("spec/fixtures/pages.zip")
  end

  subject { uploader }

  it_behaves_like "builds correct paths",
    store_dir: %r[/\h{2}/\h{2}/\h{64}/pages_deployments/\d+],
    cache_dir: %r{pages/@hashed/tmp/cache},
    work_dir: %r{pages/@hashed/tmp/work}

  context 'when object store is REMOTE' do
    before do
      stub_pages_object_storage
    end

    describe '.default_store' do
      it 'returns remote store when object storage is enabled' do
        expect(described_class.default_store).to eq(ObjectStorage::Store::REMOTE)
      end
    end

    it 'preserves original file when stores it' do
      uploader.store!(file)

      expect(File.exist?(file.path)).to be true
    end

    it_behaves_like 'builds correct paths',
      store_dir: %r[\A\h{2}/\h{2}/\h{64}/pages_deployments/\d+\z]
  end

  context 'when file is stored in valid local_path' do
    describe '.default_store' do
      it 'returns local store when object storage is not enabled' do
        expect(described_class.default_store).to eq(ObjectStorage::Store::LOCAL)
      end
    end

    it 'builds the right file path' do
      uploader.store!(file)

      expect(uploader.file.path).to match(
        %r[#{uploader.root}/@hashed/\h{2}/\h{2}/\h{64}/pages_deployments/#{pages_deployment.id}/pages.zip]
      )
    end

    it 'preserves original file when stores it' do
      uploader.store!(file)

      expect(File.exist?(file.path)).to be true
    end
  end

  describe '.object_store_credentials' do
    before do
      allow(described_class).to receive(:object_store_options).and_return(
        Gitlab::Configs.build_options(
          'enabled' => true,
          'remote_directory' => 'pages',
          'connection' => connection.deep_stringify_keys
        )
      )
    end

    subject(:credentials) { described_class.object_store_credentials }

    context 'when the provider is AWS with an IAM profile' do
      let(:connection) { { provider: 'AWS', use_iam_profile: true, region: 'eu-central-1' } }

      it 'defaults the credential refresh threshold to cover the Pages cache lifetime' do
        expect(credentials).to eq(
          provider: 'AWS',
          use_iam_profile: true,
          region: 'eu-central-1',
          aws_credentials_refresh_threshold_seconds: described_class::AWS_CREDENTIALS_REFRESH_THRESHOLD_SECONDS
        )
      end

      it 'is honoured by the fog connection built from the credentials' do
        Fog.mock!
        allow(Fog::AWS::Storage).to receive(:fetch_credentials).and_return(
          aws_access_key_id: 'AKIATEMPORARY',
          aws_secret_access_key: SecureRandom.hex(20),
          aws_session_token: SecureRandom.hex(20),
          aws_credentials_expire_at: 1.hour.from_now
        )

        storage = Fog::Storage.new(credentials)

        expect(storage.send(:credentials_refresh_threshold))
          .to eq(described_class::AWS_CREDENTIALS_REFRESH_THRESHOLD_SECONDS)
      end

      context 'when use_iam_profile is a string' do
        let(:connection) { { provider: 'AWS', use_iam_profile: 'true', region: 'eu-central-1' } }

        it 'defaults the credential refresh threshold' do
          expect(credentials[:aws_credentials_refresh_threshold_seconds])
            .to eq(described_class::AWS_CREDENTIALS_REFRESH_THRESHOLD_SECONDS)
        end
      end

      context 'when the refresh threshold is set explicitly' do
        let(:connection) do
          {
            provider: 'AWS',
            use_iam_profile: true,
            region: 'eu-central-1',
            aws_credentials_refresh_threshold_seconds: 60
          }
        end

        it 'keeps the explicit value' do
          expect(credentials[:aws_credentials_refresh_threshold_seconds]).to eq(60)
        end
      end
    end

    context 'when the provider is AWS with static keys' do
      let(:connection) { { provider: 'AWS', aws_access_key_id: 'static-id', region: 'eu-central-1' } }

      it 'returns the connection settings unchanged' do
        expect(credentials).to eq(connection)
      end
    end

    context 'when the provider is AWS with use_iam_profile disabled' do
      let(:connection) { { provider: 'AWS', use_iam_profile: false, region: 'eu-central-1' } }

      it 'returns the connection settings unchanged' do
        expect(credentials).to eq(connection)
      end
    end

    context 'when the provider is not AWS' do
      let(:connection) { { provider: 'Google', google_project: 'project', use_iam_profile: true } }

      it 'returns the connection settings unchanged' do
        expect(credentials).to eq(connection)
      end
    end
  end

  describe '#trim_filename_if_needed' do
    where(:input_filename, :expected_output, :description) do
      [
        ['short_filename.zip', 'short_filename.zip', 'under 60 characters'],
        ["#{'a' * 70}.zip", "#{'a' * 70}.zip"[-60..], 'over 60 characters'],
        ["#{'a' * 56}.zip", "#{'a' * 56}.zip", 'exactly 60 characters'],
        ['very_long_file_name_with_underscores_and_numbers_123456789_and_more_text.tar.gz',
          'very_long_file_name_with_underscores_and_numbers_123456789_and_more_text.tar.gz'[-60..],
          'complex with multi-part extension']
      ]
    end

    with_them do
      it "correctly trims filename when #{params[:description]}" do
        result = uploader.send(:trim_filename_if_needed, input_filename)

        expect(result).to eq(expected_output)

        if input_filename.length > 60
          expect(result.length).to eq(60)
        else
          expect(result).to eq(input_filename)
        end
      end
    end

    it "handles nil input by returning nil" do
      expect(uploader.send(:trim_filename_if_needed, nil)).to be_nil
    end

    it "handles empty string by returning empty string" do
      expect(uploader.send(:trim_filename_if_needed, "")).to eq("")
    end
  end
end
