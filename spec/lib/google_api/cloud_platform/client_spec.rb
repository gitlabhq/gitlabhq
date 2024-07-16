# frozen_string_literal: true

require 'spec_helper'
require 'google/apis/sqladmin_v1beta4'

RSpec.describe GoogleApi::CloudPlatform::Client do
  let(:token) { 'token' }
  let(:client) { described_class.new(token, nil) }
  let(:gcp_project_id) { String('gcp_proj_id') }
  let(:operation) { true }
  let(:database_instance) { Google::Apis::SqladminV1beta4::DatabaseInstance.new(state: 'RUNNABLE') }
  let(:instance_name) { 'mock-instance-name' }
  let(:root_password) { 'mock-root-password' }
  let(:database_version) { 'mock-database-version' }
  let(:region) { 'mock-region' }
  let(:tier) { 'mock-tier' }

  let(:database_list) do
    Google::Apis::SqladminV1beta4::ListDatabasesResponse.new(
      items: [
        Google::Apis::SqladminV1beta4::Database.new(name: 'db_01', instance: database_instance),
        Google::Apis::SqladminV1beta4::Database.new(name: 'db_02', instance: database_instance)
      ])
  end

  let(:user_list) do
    Google::Apis::SqladminV1beta4::ListUsersResponse.new(
      items: [
        Google::Apis::SqladminV1beta4::User.new(name: 'user_01', instance: database_instance),
        Google::Apis::SqladminV1beta4::User.new(name: 'user_02', instance: database_instance)
      ])
  end

  describe '.session_key_for_redirect_uri' do
    let(:state) { 'random_string' }

    subject { described_class.session_key_for_redirect_uri(state) }

    it 'creates a new session key' do
      is_expected.to eq('cloud_platform_second_redirect_uri_random_string')
    end
  end

  describe '.new_session_key_for_redirect_uri' do
    it 'generates a new session key' do
      expect { |b| described_class.new_session_key_for_redirect_uri(&b) }
        .to yield_with_args(String)
    end
  end

  describe '#validate_token' do
    subject { client.validate_token(expires_at) }

    let(:expires_at) { 1.hour.since.utc.strftime('%s') }

    context 'when token is nil' do
      let(:token) { nil }

      it { is_expected.to be_falsy }
    end

    context 'when expires_at is nil' do
      let(:expires_at) { nil }

      it { is_expected.to be_falsy }
    end

    context 'when expires in 1 hour' do
      it { is_expected.to be_truthy }
    end

    context 'when expires in 10 minutes' do
      let(:expires_at) { 5.minutes.since.utc.strftime('%s') }

      it { is_expected.to be_falsy }
    end
  end

  describe '#user_agent_header' do
    subject { client.instance_eval { user_agent_header } }

    it 'returns a RequestOptions object' do
      expect(subject).to be_instance_of(Google::Apis::RequestOptions)
    end

    it 'has the correct GitLab version in User-Agent header' do
      stub_const('Gitlab::VERSION', '10.3.0-pre')

      expect(subject.header).to eq({ 'User-Agent': 'GitLab/10.3 (GPN:GitLab;)' })
    end
  end

  describe '#list_projects' do
    subject { client.list_projects }

    let(:gcp_project_01) { Google::Apis::CloudresourcemanagerV1::Project.new(project_id: '01') }
    let(:gcp_project_02) { Google::Apis::CloudresourcemanagerV1::Project.new(project_id: '02') }
    let(:gcp_project_03) { Google::Apis::CloudresourcemanagerV1::Project.new(project_id: '03') }
    let(:list_of_projects) { [gcp_project_03, gcp_project_01, gcp_project_02] }

    let(:next_page_token) { nil }
    let(:operation) { double(projects: list_of_projects, next_page_token: next_page_token) }

    it 'calls Google Api CloudResourceManagerService#list_projects' do
      expect_any_instance_of(Google::Apis::CloudresourcemanagerV1::CloudResourceManagerService)
        .to receive(:list_projects)
              .and_return(operation)

      is_expected.to contain_exactly(gcp_project_01, gcp_project_02, gcp_project_03)
    end
  end

  describe '#create_service_account' do
    subject { client.create_service_account(spy, spy, spy) }

    let(:operation) { double('Service Account') }

    it 'calls Google Api IamService#create_service_account' do
      expect_any_instance_of(Google::Apis::IamV1::IamService)
        .to receive(:create_service_account)
              .with(any_args)
              .and_return(operation)
      is_expected.to eq(operation)
    end
  end

  describe '#create_service_account_key' do
    subject { client.create_service_account_key(spy, spy) }

    let(:operation) { double('Service Account Key') }

    it 'calls Google Api IamService#create_service_account_key' do
      expect_any_instance_of(Google::Apis::IamV1::IamService)
        .to receive(:create_service_account_key)
              .with(any_args)
              .and_return(operation)
      is_expected.to eq(operation)
    end
  end

  describe 'grant_service_account_roles' do
    subject { client.grant_service_account_roles(spy, spy) }

    it 'calls Google Api CloudResourceManager#set_iam_policy' do
      mock_gcp_id = 'mock-gcp-id'
      mock_email = 'mock@email.com'
      mock_policy = Struct.new(:bindings).new([])
      mock_body = []

      expect(Google::Apis::CloudresourcemanagerV1::Binding).to receive(:new)
                                                                 .with({ role: 'roles/iam.serviceAccountUser', members: ["serviceAccount:#{mock_email}"] })

      expect(Google::Apis::CloudresourcemanagerV1::Binding).to receive(:new)
                                                                 .with({ role: 'roles/artifactregistry.admin', members: ["serviceAccount:#{mock_email}"] })

      expect(Google::Apis::CloudresourcemanagerV1::Binding).to receive(:new)
                                                                 .with({ role: 'roles/cloudbuild.builds.builder', members: ["serviceAccount:#{mock_email}"] })

      expect(Google::Apis::CloudresourcemanagerV1::Binding).to receive(:new)
                                                                 .with({ role: 'roles/run.admin', members: ["serviceAccount:#{mock_email}"] })

      expect(Google::Apis::CloudresourcemanagerV1::Binding).to receive(:new)
                                                                 .with({ role: 'roles/storage.admin', members: ["serviceAccount:#{mock_email}"] })

      expect(Google::Apis::CloudresourcemanagerV1::Binding).to receive(:new)
                                                                 .with({ role: 'roles/cloudsql.client', members: ["serviceAccount:#{mock_email}"] })

      expect(Google::Apis::CloudresourcemanagerV1::Binding).to receive(:new)
                                                                 .with({ role: 'roles/browser', members: ["serviceAccount:#{mock_email}"] })

      expect(Google::Apis::CloudresourcemanagerV1::SetIamPolicyRequest).to receive(:new).and_return([])

      expect_next_instance_of(Google::Apis::CloudresourcemanagerV1::CloudResourceManagerService) do |instance|
        expect(instance).to receive(:get_project_iam_policy)
                              .with(mock_gcp_id)
                              .and_return(mock_policy)
        expect(instance).to receive(:set_project_iam_policy)
                              .with(mock_gcp_id, mock_body)
      end

      client.grant_service_account_roles(mock_gcp_id, mock_email)
    end
  end

  describe '#enable_cloud_run' do
    subject { client.enable_cloud_run(gcp_project_id) }

    it 'calls Google Api IamService#create_service_account_key' do
      expect_any_instance_of(Google::Apis::ServiceusageV1::ServiceUsageService)
        .to receive(:enable_service)
              .with("projects/#{gcp_project_id}/services/run.googleapis.com")
              .and_return(operation)
      is_expected.to eq(operation)
    end
  end

  describe '#enable_artifacts_registry' do
    subject { client.enable_artifacts_registry(gcp_project_id) }

    it 'calls Google Api IamService#create_service_account_key' do
      expect_any_instance_of(Google::Apis::ServiceusageV1::ServiceUsageService)
        .to receive(:enable_service)
              .with("projects/#{gcp_project_id}/services/artifactregistry.googleapis.com")
              .and_return(operation)
      is_expected.to eq(operation)
    end
  end

  describe '#enable_cloud_build' do
    subject { client.enable_cloud_build(gcp_project_id) }

    it 'calls Google Api IamService#create_service_account_key' do
      expect_any_instance_of(Google::Apis::ServiceusageV1::ServiceUsageService)
        .to receive(:enable_service)
              .with("projects/#{gcp_project_id}/services/cloudbuild.googleapis.com")
              .and_return(operation)
      is_expected.to eq(operation)
    end
  end

  describe '#enable_cloud_sql_admin' do
    subject { client.enable_cloud_sql_admin(gcp_project_id) }

    it 'calls Google Api ServiceUsageService' do
      expect_any_instance_of(Google::Apis::ServiceusageV1::ServiceUsageService)
        .to receive(:enable_service)
              .with("projects/#{gcp_project_id}/services/sqladmin.googleapis.com")
              .and_return(operation)
      is_expected.to eq(operation)
    end
  end

  describe '#enable_compute' do
    subject { client.enable_compute(gcp_project_id) }

    it 'calls Google Api ServiceUsageService' do
      expect_any_instance_of(Google::Apis::ServiceusageV1::ServiceUsageService)
        .to receive(:enable_service)
              .with("projects/#{gcp_project_id}/services/compute.googleapis.com")
              .and_return(operation)
      is_expected.to eq(operation)
    end
  end

  describe '#enable_service_networking' do
    subject { client.enable_service_networking(gcp_project_id) }

    it 'calls Google Api ServiceUsageService' do
      expect_any_instance_of(Google::Apis::ServiceusageV1::ServiceUsageService)
        .to receive(:enable_service)
              .with("projects/#{gcp_project_id}/services/servicenetworking.googleapis.com")
              .and_return(operation)
      is_expected.to eq(operation)
    end
  end

  describe '#enable_visionai' do
    subject { client.enable_vision_api(gcp_project_id) }

    it 'calls Google Api ServiceUsageService' do
      expect_any_instance_of(Google::Apis::ServiceusageV1::ServiceUsageService)
        .to receive(:enable_service)
              .with("projects/#{gcp_project_id}/services/vision.googleapis.com")
              .and_return(operation)
      is_expected.to eq(operation)
    end
  end

  describe '#revoke_authorizations' do
    subject { client.revoke_authorizations }

    it 'calls the revoke endpoint' do
      stub_request(:post, "https://oauth2.googleapis.com/revoke")
        .with(
          body: "token=token",
          headers: {
            'Accept' => '*/*',
            'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
            'User-Agent' => 'Ruby'
          })
        .to_return(status: 200, body: "", headers: {})
    end
  end

  describe '#create_cloudsql_database' do
    subject { client.create_cloudsql_database(:gcp_project_id, :instance_name, :database_name) }

    it 'calls Google Api SQLAdminService#insert_database' do
      expect_any_instance_of(Google::Apis::SqladminV1beta4::SQLAdminService)
        .to receive(:insert_database)
              .with(any_args)
              .and_return(operation)
      is_expected.to eq(operation)
    end
  end

  describe '#create_cloudsql_user' do
    subject { client.create_cloudsql_user(:gcp_project_id, :instance_name, :database_name, :user_name) }

    it 'calls Google Api SQLAdminService#insert_user' do
      expect_any_instance_of(Google::Apis::SqladminV1beta4::SQLAdminService)
        .to receive(:insert_user)
              .with(any_args)
              .and_return(operation)
      is_expected.to eq(operation)
    end
  end

  describe '#get_cloudsql_instance' do
    subject { client.get_cloudsql_instance(:gcp_project_id, :instance_name) }

    it 'calls Google Api SQLAdminService#get_instance' do
      expect_any_instance_of(Google::Apis::SqladminV1beta4::SQLAdminService)
        .to receive(:get_instance)
              .with(any_args)
              .and_return(database_instance)
      is_expected.to eq(database_instance)
    end
  end

  describe '#list_cloudsql_databases' do
    subject { client.list_cloudsql_databases(:gcp_project_id, :instance_name) }

    it 'calls Google Api SQLAdminService#list_databases' do
      expect_any_instance_of(Google::Apis::SqladminV1beta4::SQLAdminService)
        .to receive(:list_databases)
              .with(any_args)
              .and_return(database_list)
      is_expected.to eq(database_list)
    end
  end

  describe '#list_cloudsql_users' do
    subject { client.list_cloudsql_users(:gcp_project_id, :instance_name) }

    it 'calls Google Api SQLAdminService#list_users' do
      expect_any_instance_of(Google::Apis::SqladminV1beta4::SQLAdminService)
        .to receive(:list_users)
              .with(any_args)
              .and_return(user_list)
      is_expected.to eq(user_list)
    end
  end

  describe '#create_cloudsql_instance' do
    subject do
      client.create_cloudsql_instance(
        gcp_project_id,
        instance_name,
        root_password,
        database_version,
        region,
        tier
      )
    end

    it 'calls Google Api SQLAdminService#insert_instance' do
      expect_any_instance_of(Google::Apis::SqladminV1beta4::SQLAdminService)
        .to receive(:insert_instance)
              .with(gcp_project_id,
                having_attributes(
                  class: ::Google::Apis::SqladminV1beta4::DatabaseInstance,
                  name: instance_name,
                  root_password: root_password,
                  database_version: database_version,
                  region: region,
                  settings: instance_of(Google::Apis::SqladminV1beta4::Settings)
                ))
              .and_return(operation)
      is_expected.to eq(operation)
    end
  end
end
