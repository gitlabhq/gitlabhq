# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GoogleCloud::SetupCloudsqlInstanceService do
  let(:random_user) { create(:user) }
  let(:project) { create(:project) }

  context 'when unauthorized user triggers worker' do
    subject do
      params = {
        gcp_project_id: :gcp_project_id,
        instance_name: :instance_name,
        database_version: :database_version,
        environment_name: :environment_name,
        is_protected: :is_protected
      }
      described_class.new(project, random_user, params).execute
    end

    it 'raises unauthorized error' do
      message = subject[:message]
      status = subject[:status]

      expect(status).to eq(:error)
      expect(message).to eq('Unauthorized user')
    end
  end

  context 'when authorized user triggers worker' do
    subject do
      user = project.creator
      params = {
        gcp_project_id: :gcp_project_id,
        instance_name: :instance_name,
        database_version: :database_version,
        environment_name: :environment_name,
        is_protected: :is_protected
      }
      described_class.new(project, user, params).execute
    end

    context 'when instance is not RUNNABLE' do
      let(:get_instance_response_pending) do
        Google::Apis::SqladminV1beta4::DatabaseInstance.new(state: 'PENDING')
      end

      it 'raises error' do
        allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |google_api_client|
          expect(google_api_client).to receive(:get_cloudsql_instance).and_return(get_instance_response_pending)
        end

        message = subject[:message]
        status = subject[:status]

        expect(status).to eq(:error)
        expect(message).to eq('CloudSQL instance not RUNNABLE: {"state":"PENDING"}')
      end
    end

    context 'when instance is RUNNABLE' do
      let(:get_instance_response_runnable) do
        Google::Apis::SqladminV1beta4::DatabaseInstance.new(
          connection_name: 'mock-connection-name',
          ip_addresses: [Struct.new(:ip_address).new('1.2.3.4')],
          state: 'RUNNABLE'
        )
      end

      let(:operation_fail) { Google::Apis::SqladminV1beta4::Operation.new(status: 'FAILED') }

      let(:operation_done) { Google::Apis::SqladminV1beta4::Operation.new(status: 'DONE') }

      context 'when database creation fails' do
        it 'raises error' do
          allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |google_api_client|
            expect(google_api_client).to receive(:get_cloudsql_instance).and_return(get_instance_response_runnable)
            expect(google_api_client).to receive(:create_cloudsql_database).and_return(operation_fail)
          end

          message = subject[:message]
          status = subject[:status]

          expect(status).to eq(:error)
          expect(message).to eq('Database creation failed: {"status":"FAILED"}')
        end
      end

      context 'when user creation fails' do
        it 'raises error' do
          allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |google_api_client|
            expect(google_api_client).to receive(:get_cloudsql_instance).and_return(get_instance_response_runnable)
            expect(google_api_client).to receive(:create_cloudsql_database).and_return(operation_done)
            expect(google_api_client).to receive(:create_cloudsql_user).and_return(operation_fail)
          end

          message = subject[:message]
          status = subject[:status]

          expect(status).to eq(:error)
          expect(message).to eq('User creation failed: {"status":"FAILED"}')
        end
      end

      context 'when database and user creation succeeds' do
        it 'stores project CI vars' do
          allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |google_api_client|
            expect(google_api_client).to receive(:get_cloudsql_instance).and_return(get_instance_response_runnable)
            expect(google_api_client).to receive(:create_cloudsql_database).and_return(operation_done)
            expect(google_api_client).to receive(:create_cloudsql_user).and_return(operation_done)
          end

          subject

          aggregate_failures 'test generated vars' do
            variables = project.reload.variables

            expect(variables.count).to eq(8)
            expect(variables.find_by(key: 'GCP_PROJECT_ID').value).to eq("gcp_project_id")
            expect(variables.find_by(key: 'GCP_CLOUDSQL_INSTANCE_NAME').value).to eq("instance_name")
            expect(variables.find_by(key: 'GCP_CLOUDSQL_CONNECTION_NAME').value).to eq("mock-connection-name")
            expect(variables.find_by(key: 'GCP_CLOUDSQL_PRIMARY_IP_ADDRESS').value).to eq("1.2.3.4")
            expect(variables.find_by(key: 'GCP_CLOUDSQL_VERSION').value).to eq("database_version")
            expect(variables.find_by(key: 'GCP_CLOUDSQL_DATABASE_NAME').value).to eq("main_db")
            expect(variables.find_by(key: 'GCP_CLOUDSQL_DATABASE_USER').value).to eq("main_user")
            expect(variables.find_by(key: 'GCP_CLOUDSQL_DATABASE_PASS').value).to be_present
          end
        end

        context 'when the ci variable already exists' do
          before do
            create(
              :ci_variable,
              project: project,
              key: 'GCP_PROJECT_ID',
              value: 'previous_gcp_project_id',
              environment_scope: :environment_name
            )
          end

          it 'overwrites existing GCP_PROJECT_ID var' do
            allow_next_instance_of(GoogleApi::CloudPlatform::Client) do |google_api_client|
              expect(google_api_client).to receive(:get_cloudsql_instance).and_return(get_instance_response_runnable)
              expect(google_api_client).to receive(:create_cloudsql_database).and_return(operation_done)
              expect(google_api_client).to receive(:create_cloudsql_user).and_return(operation_done)
            end

            subject

            variables = project.reload.variables
            value = variables.find_by(key: 'GCP_PROJECT_ID', environment_scope: :environment_name).value
            expect(value).to eq("gcp_project_id")
          end
        end
      end
    end
  end
end
