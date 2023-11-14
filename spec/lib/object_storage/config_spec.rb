# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'
require 'fog/core'

RSpec.describe ObjectStorage::Config, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  let(:region) { 'us-east-1' }
  let(:bucket_name) { 'test-bucket' }
  let(:credentials) do
    {
      provider: 'AWS',
      aws_access_key_id: 'AWS_ACCESS_KEY_ID',
      aws_secret_access_key: 'AWS_SECRET_ACCESS_KEY',
      region: region
    }
  end

  let(:storage_options) do
    {
      server_side_encryption: 'AES256',
      server_side_encryption_kms_key_id: 'arn:aws:12345'
    }
  end

  let(:raw_config) do
    {
      enabled: true,
      connection: credentials,
      remote_directory: bucket_name,
      storage_options: storage_options
    }
  end

  subject { described_class.new(raw_config.as_json) }

  describe '#credentials' do
    it { expect(subject.credentials).to eq(credentials) }
  end

  describe '#storage_options' do
    it { expect(subject.storage_options).to eq(storage_options) }
  end

  describe '#enabled?' do
    it { expect(subject.enabled?).to eq(true) }
  end

  describe '#bucket' do
    it { expect(subject.bucket).to eq(bucket_name) }
  end

  describe '#use_iam_profile' do
    it { expect(subject.use_iam_profile?).to be false }
  end

  describe '#use_path_style' do
    it { expect(subject.use_path_style?).to be false }
  end

  context 'with unconsolidated settings' do
    describe 'consolidated_settings? returns false' do
      it { expect(subject.consolidated_settings?).to be false }
    end
  end

  context 'with consolidated settings' do
    before do
      raw_config[:consolidated_settings] = true
    end

    describe 'consolidated_settings? returns true' do
      it { expect(subject.consolidated_settings?).to be true }
    end
  end

  context 'with IAM profile configured' do
    where(:value, :expected) do
      true    | true
      "true"  | true
      "yes"   | true
      false   | false
      "false" | false
      "no"    | false
      nil     | false
    end

    with_them do
      before do
        credentials[:use_iam_profile] = value
      end

      it 'coerces the value to a boolean' do
        expect(subject.use_iam_profile?).to be expected
      end
    end
  end

  context 'with path style configured' do
    where(:value, :expected) do
      true    | true
      "true"  | true
      "yes"   | true
      false   | false
      "false" | false
      "no"    | false
      nil     | false
    end

    with_them do
      before do
        credentials[:path_style] = value
      end

      it 'coerces the value to a boolean' do
        expect(subject.use_path_style?).to be expected
      end
    end
  end

  context 'with hostname style access' do
    it '#use_path_style? returns false' do
      expect(subject.use_path_style?).to be false
    end
  end

  context 'with AWS credentials' do
    it { expect(subject.provider).to eq('AWS') }
    it { expect(subject.aws?).to be true }
    it { expect(subject.google?).to be false }
    it { expect(subject.credentials).to eq(credentials) }

    context 'with FIPS enabled', :fips_mode do
      it { expect(subject.credentials).to eq(credentials.merge(disable_content_md5_validation: true)) }
    end
  end

  context 'with Google credentials' do
    let(:credentials) do
      {
        provider: 'Google',
        google_json_key_location: '/path/to/gcp.json'
      }
    end

    it { expect(subject.provider).to eq('Google') }
    it { expect(subject.aws?).to be false }
    it { expect(subject.google?).to be true }
    it { expect(subject.fog_attributes).to eq({}) }
  end

  context 'with SSE-KMS enabled' do
    it { expect(subject.aws_server_side_encryption_enabled?).to be true }
    it { expect(subject.server_side_encryption).to eq('AES256') }
    it { expect(subject.server_side_encryption_kms_key_id).to eq('arn:aws:12345') }
    it { expect(subject.fog_attributes.keys).to match_array(%w[x-amz-server-side-encryption x-amz-server-side-encryption-aws-kms-key-id]) }
  end

  context 'with only server side encryption enabled' do
    let(:storage_options) { { server_side_encryption: 'AES256' } }

    it { expect(subject.aws_server_side_encryption_enabled?).to be true }
    it { expect(subject.server_side_encryption).to eq('AES256') }
    it { expect(subject.server_side_encryption_kms_key_id).to be_nil }
    it { expect(subject.fog_attributes).to eq({ 'x-amz-server-side-encryption' => 'AES256' }) }
  end

  context 'without encryption enabled' do
    let(:storage_options) { {} }

    it { expect(subject.aws_server_side_encryption_enabled?).to be false }
    it { expect(subject.server_side_encryption).to be_nil }
    it { expect(subject.server_side_encryption_kms_key_id).to be_nil }
    it { expect(subject.fog_attributes).to eq({}) }
  end

  context 'with object storage disabled' do
    before do
      raw_config['enabled'] = false
    end

    it { expect(subject.enabled?).to be false }
  end
end
