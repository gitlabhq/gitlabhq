# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Configuration, feature_category: :importers do
  using RSpec::Parameterized::TableSyntax

  describe 'associations' do
    it { is_expected.to belong_to(:offline_export).class_name('Import::Offline::Export') }
    it { is_expected.to belong_to(:organization) }
  end

  describe 'encryption', :aggregate_failures do
    it 'encrypts object_storage_credentials' do
      configuration = create(:offline_configuration)
      expect(configuration.encrypted_attribute?(:object_storage_credentials)).to be(true)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to define_enum_for(:provider).with_values(%i[aws minio]) }

    it { is_expected.to validate_presence_of(:export_prefix) }
    it { is_expected.to validate_presence_of(:object_storage_credentials) }

    it { is_expected.to validate_presence_of(:bucket) }
    it { is_expected.to validate_length_of(:bucket).is_at_least(3).is_at_most(63) }
    it { is_expected.to allow_value('s3-compliant.bucket-name1').for(:bucket) }
    it { is_expected.not_to allow_value('CapitalLetters').for(:bucket) }
    it { is_expected.not_to allow_value('special.characters/\?<>@&=_ ').for(:bucket) }

    describe '#provider' do
      context 'when in development environment' do
        before do
          allow(Rails.env).to receive(:development?).and_return(true)
        end

        it { is_expected.to allow_values('minio', 'aws').for(:provider) }
      end

      context 'when not in development environment' do
        before do
          allow(Rails.env).to receive(:development?).and_return(false)
        end

        it { is_expected.to allow_value('aws').for(:provider) }
        it { is_expected.not_to allow_value('minio').for(:provider) }
      end
    end

    describe '#object_storage_credentials' do
      subject(:valid?) do
        build(:offline_configuration, provider: provider, object_storage_credentials: valid_credentials).valid?
      end

      context 'when provider is AWS' do
        let(:provider) { :aws }
        let(:valid_credentials) do
          {
            aws_access_key_id: 'AwsUserAccessKey123',
            aws_secret_access_key: 'aws/secret+access/key',
            region: 'us-east-1',
            path_style: false
          }
        end

        context 'with valid credentials' do
          it { is_expected.to be(true) }
        end

        context 'with an invalid credential value' do
          where(:credential, :value) do
            :aws_access_key_id     | ('a' * 129)
            :aws_access_key_id     | ('a' * 129)
            :aws_access_key_id     | 'special+/chars'
            :aws_access_key_id     | 1234567890
            :aws_access_key_id     | ''
            :aws_access_key_id     | nil
            :aws_secret_access_key | ('a' * 129)
            :aws_secret_access_key | ('a' * 129)
            :aws_secret_access_key | 'bad-special-chars?!'
            :aws_secret_access_key | 1234567890
            :aws_secret_access_key | ''
            :aws_secret_access_key | nil
            :region                | ('a' * 51)
            :region                | ''
            :region                | nil
            :path_style            | 'true'
            :path_style            | 1
            :path_style            | ''
            :path_style            | nil
            :endpoint              | 'https://gitlab.com'
          end

          with_them do
            before do
              valid_credentials.merge!({ credential => value })
            end

            it { is_expected.to be(false) }
          end
        end
      end

      context 'when provider is MinIO' do
        let(:provider) { :minio }
        let(:valid_credentials) do
          {
            aws_access_key_id: 'MinIO-user+access@key123/456?',
            aws_secret_access_key: 'minio-secret-access-key',
            region: 'gdk',
            endpoint: 'https://minio.example.com',
            path_style: true
          }
        end

        before do
          allow(Rails.env).to receive(:development?).and_return(true)
        end

        context 'with valid credentials' do
          it { is_expected.to be(true) }
        end

        context 'with an invalid credential value' do
          where(:credential, :value) do
            :aws_access_key_id     | ('a' * 256)
            :aws_access_key_id     | 1234567890
            :aws_access_key_id     | ''
            :aws_access_key_id     | nil
            :aws_secret_access_key | ('a' * 256)
            :aws_secret_access_key | ('a' * 256)
            :aws_secret_access_key | 1234567890
            :aws_secret_access_key | ''
            :aws_secret_access_key | nil
            :region                | ('a' * 256)
            :region                | ''
            :region                | nil
            :path_style            | 'true'
            :path_style            | 1
            :path_style            | ''
            :path_style            | nil
            :endpoint              | 'ftp://ftp-endpoint'
            :endpoint              | 'not a URI'
            :endpoint              | ''
            :endpoint              | nil
            :endpoint              | "https://gitlab.#{'a' * 256}.com"
          end

          with_them do
            before do
              valid_credentials.merge!({ credential => value })
            end

            it { is_expected.to be(false) }
          end
        end
      end
    end
  end

  describe 'callbacks' do
    describe '#generate_export_prefix', time_travel_to: '2025-11-04 12:35:45.000000' do
      it 'sets export_prefix on initalization' do
        configuration = described_class.new

        expect(configuration.export_prefix).to match(/^2025-11-04_12-35-45_export_[a-zA-Z0-9]{8}$/)
      end

      it 'does not overwrite existing prefixes' do
        configuration = create(:offline_configuration, export_prefix: 'existing_prefix')

        expect(described_class.find(configuration.id).export_prefix).to eq('existing_prefix')
      end
    end
  end
end
