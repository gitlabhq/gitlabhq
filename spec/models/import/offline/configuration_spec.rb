# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Configuration, feature_category: :importers do
  using RSpec::Parameterized::TableSyntax

  describe 'associations' do
    it { is_expected.to belong_to(:offline_export).class_name('Import::Offline::Export').optional }
    it { is_expected.to belong_to(:bulk_import).optional }
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
    it { is_expected.to define_enum_for(:provider).with_values(%i[aws s3_compatible gcs_hmac gcs]) }

    it { is_expected.to validate_presence_of(:export_prefix) }
    it { is_expected.to validate_presence_of(:object_storage_credentials) }

    it { is_expected.to validate_presence_of(:bucket) }
    it { is_expected.to validate_length_of(:bucket).is_at_least(3).is_at_most(63) }
    it { is_expected.to allow_value('s3-compliant.bucket-name1').for(:bucket) }
    it { is_expected.not_to allow_value('CapitalLetters').for(:bucket) }
    it { is_expected.not_to allow_value('special.characters/\?<>@&=_ ').for(:bucket) }

    describe 'bulk_import and offline_export should be mutually exclusive' do
      let(:bulk_import) { build(:bulk_import) }
      let(:offline_export) { build(:offline_export) }

      where(:bulk_import_object, :offline_export_object, :expected_result) do
        nil               | nil                  | false
        ref(:bulk_import) | nil                  | true
        nil               | ref(:offline_export) | true
        ref(:bulk_import) | ref(:offline_export) | false
      end

      with_them do
        it 'validates exclusivity' do
          export = build(:offline_configuration, bulk_import: bulk_import_object, offline_export: offline_export_object)
          expect(export.valid?).to be expected_result
        end
      end
    end

    describe '#provider' do
      context 'when S3 compatible storage is allowed for offline transfer' do
        before do
          stub_application_setting(allow_s3_compatible_storage_for_offline_transfer: true)
        end

        it { is_expected.to allow_values('s3_compatible', 'aws', 'gcs_hmac').for(:provider) }
      end

      context 'when S3 compatible storage is not allowed for offline transfer' do
        before do
          stub_application_setting(allow_s3_compatible_storage_for_offline_transfer: false)
        end

        it { is_expected.to allow_values('aws', 'gcs_hmac').for(:provider) }
        it { is_expected.not_to allow_value('s3_compatible').for(:provider) }
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

      context 'when provider is S3-compatible' do
        let(:provider) { :s3_compatible }
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
          stub_application_setting(allow_s3_compatible_storage_for_offline_transfer: true)
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

      context 'when provider is GCS with a service account JSON key' do
        let(:provider) { :gcs }
        let(:json_key) do
          Gitlab::Json.dump(
            type: 'service_account',
            project_id: 'gitlab-project',
            private_key: "-----BEGIN PRIVATE KEY-----\nFAKEKEYCONTENTS\n-----END PRIVATE KEY-----\n",
            client_email: 'gcs@gitlab-project.iam.gserviceaccount.com'
          )
        end

        let(:valid_credentials) do
          {
            google_project: 'gitlab-project',
            google_json_key_string: json_key
          }
        end

        context 'with valid credentials' do
          it { is_expected.to be(true) }
        end

        context 'with an invalid credential value' do
          where(:credential, :value) do
            :google_project         | ('a' * 256)
            :google_project         | ''
            :google_project         | nil
            :google_project         | 1234567890
            :google_project         | 'Invalid_Project_ID'
            :google_json_key_string | ('a' * 16385)
            :google_json_key_string | ''
            :google_json_key_string | nil
            :google_json_key_string | 1234567890
          end

          with_them do
            before do
              valid_credentials.merge!({ credential => value })
            end

            it { is_expected.to be(false) }
          end
        end

        context 'when the service account key is not valid JSON' do
          before do
            valid_credentials[:google_json_key_string] = 'not-json'
          end

          it { is_expected.to be(false) }
        end

        context 'when the service account key is valid JSON but not an object' do
          before do
            valid_credentials[:google_json_key_string] = '["service_account"]'
          end

          it { is_expected.to be(false) }
        end

        context 'when the service account key is missing required fields' do
          before do
            valid_credentials[:google_json_key_string] = Gitlab::Json.dump(
              type: 'service_account',
              project_id: 'gitlab-project'
            )
          end

          it { is_expected.to be(false) }
        end

        context 'when the service account key has an invalid project_id format' do
          before do
            valid_credentials[:google_json_key_string] = Gitlab::Json.dump(
              type: 'service_account',
              project_id: 'Invalid_Project_ID',
              private_key: "-----BEGIN PRIVATE KEY-----\nFAKEKEYCONTENTS\n-----END PRIVATE KEY-----\n",
              client_email: 'gcs@gitlab-project.iam.gserviceaccount.com'
            )
          end

          it { is_expected.to be(false) }
        end

        context 'when the service account key has a type other than service_account' do
          before do
            valid_credentials[:google_json_key_string] = Gitlab::Json.dump(
              type: 'authorized_user',
              project_id: 'gitlab-project',
              private_key: "-----BEGIN PRIVATE KEY-----\nFAKEKEYCONTENTS\n-----END PRIVATE KEY-----\n",
              client_email: 'gcs@gitlab-project.iam.gserviceaccount.com'
            )
          end

          it { is_expected.to be(false) }
        end

        context 'when the service account key carries fields beyond the required ones' do
          let(:json_key) do
            Gitlab::Json.dump(
              type: 'service_account',
              project_id: 'gitlab-project',
              private_key: "-----BEGIN PRIVATE KEY-----\nFAKEKEYCONTENTS\n-----END PRIVATE KEY-----\n",
              client_email: 'gcs@gitlab-project.iam.gserviceaccount.com',
              private_key_id: 'abc123',
              client_id: '123456789',
              token_uri: 'https://oauth2.googleapis.com/token',
              unexpected_field: 'value'
            )
          end

          it { is_expected.to be(true) }

          it 'flattens the key into individual fields and drops the non-required ones' do
            configuration = build(:offline_configuration, provider: provider,
              object_storage_credentials: valid_credentials)
            configuration.validate

            expect(configuration.object_storage_credentials.keys).to contain_exactly(
              'google_project', 'type', 'project_id', 'private_key', 'client_email'
            )
          end
        end

        context 'with an unexpected credential key' do
          before do
            valid_credentials[:google_application_default] = true
          end

          it { is_expected.to be(false) }
        end
      end

      context 'when provider is GCS with HMAC keys' do
        let(:provider) { :gcs_hmac }
        let(:valid_credentials) do
          {
            google_storage_access_key_id: 'GOOG1EXAMPLEACCESSKEY123',
            google_storage_secret_access_key: 'AbCd+EfGh/IjKlMnOpQrStUvWxYz0123456789K=', # gitleaks:allow
            region: 'us-east1',
            path_style: true
          }
        end

        context 'with valid credentials' do
          it { is_expected.to be(true) }
        end

        context 'with valid credentials omitting the optional path_style' do
          before do
            valid_credentials.delete(:path_style)
          end

          it { is_expected.to be(true) }
        end

        context 'with an invalid credential value' do
          where(:credential, :value) do
            :google_storage_access_key_id     | ('a' * 256)
            :google_storage_access_key_id     | ('a' * 23)
            :google_storage_access_key_id     | 'GOOG1-INVALID-CHARS'
            :google_storage_access_key_id     | ''
            :google_storage_access_key_id     | nil
            :google_storage_secret_access_key | ('a' * 256)
            :google_storage_secret_access_key | ('a' * 39)
            :google_storage_secret_access_key | 'gcs-hmac-secret-with-dashes'
            :google_storage_secret_access_key | ''
            :google_storage_secret_access_key | nil
            :region                           | ('a' * 256)
            :region                           | ''
            :region                           | nil
            :path_style                       | 'true'
            :path_style                       | 1
            :google_json_key_string           | '{"type":"service_account"}'
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

    describe '#entity_prefix_mapping' do
      let(:configuration) { build(:offline_configuration) }
      let(:valid_mapping) do
        {
          'my-group/my-project' => 'project_1',
          'my-group' => 'group_2'
        }
      end

      it { is_expected.to allow_value(valid_mapping).for(:entity_prefix_mapping) }

      context 'with an invalid source full path key' do
        where(:invalid_key) do
          [
            '',
            nil,
            'has spaces/in path',
            'has?forbidden!special@chars'
          ]
        end

        with_them do
          let(:invalid_mapping) { { invalid_key => 'group_123' } }

          it { is_expected.not_to allow_value(invalid_mapping).for(:entity_prefix_mapping) }
        end
      end

      context 'with an invalid entity prefix' do
        where(:invalid_entity_prefix) do
          [
            'organization_123',
            'project',
            '123',
            '',
            '_',
            'project/123',
            'project_123_123',
            123,
            []
          ]
        end

        with_them do
          let(:invalid_mapping) { valid_mapping['some/project'] = invalid_entity_prefix }

          it { is_expected.not_to allow_value(invalid_mapping).for(:entity_prefix_mapping) }
        end
      end
    end
  end

  describe 'callbacks' do
    describe '#generate_export_prefix', time_travel_to: '2025-11-04 12:35:45.000000' do
      it 'sets export_prefix on initialization' do
        configuration = described_class.new

        expect(configuration.export_prefix).to match(/^2025-11-04_12-35-45_export_[a-zA-Z0-9]{8}$/)
      end

      it 'does not overwrite existing prefixes' do
        configuration = create(:offline_configuration, export_prefix: 'existing_prefix')

        expect(described_class.find(configuration.id).export_prefix).to eq('existing_prefix')
      end
    end
  end

  describe '#endpoint' do
    context 'when credentials include an endpoint' do
      it 'returns the endpoint' do
        configuration = build(:offline_configuration, :s3_compatible)

        expect(configuration.endpoint).to eq('https://minio.example.com')
      end
    end

    context 'when credentials do not include an endpoint' do
      it 'returns nil' do
        configuration = build(:offline_configuration, :aws_s3)

        expect(configuration.endpoint).to be_nil
      end
    end

    context 'when credentials are not present' do
      it 'returns nil' do
        configuration = build(:offline_configuration)
        allow(configuration).to receive(:object_storage_credentials).and_return(nil)

        expect(configuration.endpoint).to be_nil
      end
    end
  end

  describe '#entity_prefix_for_path' do
    let(:configuration) do
      build(:offline_configuration, entity_prefix_mapping: {
        'my-group/my-project' => 'project_1',
        'my-group' => 'group_2'
      })
    end

    context 'when the path exists in the mapping' do
      it 'returns the entity prefix for a project path' do
        expect(configuration.entity_prefix_for_path('my-group/my-project')).to eq('project_1')
      end

      it 'returns the entity prefix for a group path' do
        expect(configuration.entity_prefix_for_path('my-group')).to eq('group_2')
      end
    end

    context 'when the path does not exist in the mapping' do
      it 'returns nil' do
        expect(configuration.entity_prefix_for_path('unknown/path')).to be_nil
      end
    end
  end

  describe '#subgroup_paths_for' do
    let(:configuration) do
      build(:offline_configuration, entity_prefix_mapping: {
        'root-group' => 'group_1',
        'root-group/source-group' => 'group_2',
        'root-group/source-group/subgroup-1' => 'group_3',
        'root-group/source-group/subgroup-2' => 'group_4',
        'root-group/source-group/subgroup-1/descendant-group' => 'group_5',
        'root-group/source-group/subgroup-1/project' => 'project_1',
        'root-group/source-group/project' => 'project_2',
        'root-group/other-group' => 'group_6',
        'other-root-group/source-group' => 'group_7',
        'other-root-group/source-group/other-subgroup' => 'group_8',
        'source-group/other-subgroup' => 'group_9'
      })
    end

    it 'returns the immediate descendant subgroups' do
      expect(configuration.subgroup_paths_for('root-group/source-group')).to contain_exactly(
        { 'full_path' => 'root-group/source-group/subgroup-1', 'path' => 'subgroup-1' },
        { 'full_path' => 'root-group/source-group/subgroup-2', 'path' => 'subgroup-2' }
      )
    end

    context 'when there are no direct descendant subgroups' do
      let(:configuration) do
        build(:offline_configuration, entity_prefix_mapping: {
          'root-group/source-group' => 'group_2',
          'root-group/source-group/subgroup-1/descendant-group' => 'group_5',
          'root-group/source-group/subgroup-1/project' => 'project_1'
        })
      end

      it 'returns an empty array' do
        expect(configuration.subgroup_paths_for('root-group/source-group')).to eq([])
      end
    end
  end

  describe '#project_paths_for' do
    let(:configuration) do
      build(:offline_configuration, entity_prefix_mapping: {
        'root-group' => 'group_1',
        'root-group/source-group' => 'group_2',
        'root-group/source-group/subgroup-1' => 'group_3',
        'root-group/source-group/project-1' => 'project_1',
        'root-group/source-group/project-2' => 'project_2',
        'root-group/source-group/subgroup-1/descendant-project' => 'project_3',
        'root-group/project' => 'project_4',
        'other-root-group/source-group/other-project' => 'project_5',
        'source-group/other-project' => 'project_6'
      })
    end

    it 'returns the immediate descendant projects' do
      expect(configuration.project_paths_for('root-group/source-group')).to contain_exactly(
        { 'full_path' => 'root-group/source-group/project-1', 'path' => 'project-1' },
        { 'full_path' => 'root-group/source-group/project-2', 'path' => 'project-2' }
      )
    end

    context 'when there are no direct descendant projects' do
      let(:configuration) do
        build(:offline_configuration, entity_prefix_mapping: {
          'root-group/source-group' => 'group_2',
          'root-group/source-group/subgroup-1' => 'group_3',
          'root-group/source-group/subgroup-1/descendant-project' => 'project_3'
        })
      end

      it 'returns an empty array' do
        expect(configuration.project_paths_for('root-group/source-group')).to eq([])
      end
    end
  end
end
