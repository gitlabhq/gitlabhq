# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::BatchedBackgroundOperations, feature_category: :database do
  let_it_be(:admin) { create(:admin) }

  describe 'GET /admin/batched_background_operations/:id' do
    let_it_be(:operation) { create(:background_operation_worker_cell_local) }
    let(:path) { "/admin/batched_background_operations/#{operation.id}" }

    it_behaves_like "GET request permissions for admin mode"

    it_behaves_like 'authorizing granular token permissions', :read_batched_background_operation do
      let(:boundary_object) { :instance }
      let(:user) { admin }
      let(:request) do
        get api(path, personal_access_token: pat)
      end
    end

    context 'when is an admin user' do
      it 'returns a single batched background operation' do
        get api(path, admin, admin_mode: true)

        aggregate_failures "testing response" do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq(operation.external_id)
          expect(json_response['partition']).to eq(operation.partition)
          expect(json_response['job_class_name']).to eq(operation.job_class_name)
          expect(json_response['table_name']).to eq(operation.table_name)
          expect(json_response['column_name']).to eq(operation.column_name)
          expect(json_response['status']).to eq(operation.status_name.to_s)
        end
      end

      context 'when the operation does not exist' do
        it 'returns not found' do
          get api("/admin/batched_background_operations/#{non_existing_record_id}", admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when multiple databases are enabled' do
        let(:database) { :ci }
        let(:schema) { :gitlab_ci }
        let(:ci_model) { Ci::ApplicationRecord }
        let(:params) { { database: database } }

        before do
          skip_if_multiple_databases_not_setup
        end

        context 'when CI database is provided' do
          let(:db_config) do
            instance_double(ActiveRecord::DatabaseConfigurations::HashConfig, name: 'fake_db', database: 'db')
          end

          let(:default_model) { ActiveRecord::Base }
          let(:base_models) { { 'fake_db' => default_model, database.to_s => ci_model }.with_indifferent_access }

          it "uses CI database connection" do
            allow(Gitlab::Database).to receive_messages(
              db_config_for_connection: db_config,
              database_base_models: base_models
            )

            expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(ci_model.connection).and_yield

            get api(path, admin, admin_mode: true), params: params
          end

          context 'when the database name does not exist' do
            let(:database) { :wrong_database }

            it 'returns bad request', :aggregate_failures do
              get api(path, admin, admin_mode: true), params: params

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(response.body).to include('database does not have a valid value')
            end
          end
        end
      end
    end
  end

  describe 'GET /admin/batched_background_operations' do
    let!(:operation) { create(:background_operation_worker_cell_local) }
    let(:path) { '/admin/batched_background_operations' }

    it_behaves_like "GET request permissions for admin mode"

    it_behaves_like 'authorizing granular token permissions', :read_batched_background_operation do
      let(:boundary_object) { :instance }
      let(:user) { admin }
      let(:request) do
        get api(path, personal_access_token: pat)
      end
    end

    context 'when is an admin user' do
      it 'returns cell-local batched background operations' do
        get api(path, admin, admin_mode: true)

        aggregate_failures "testing response" do
          expect(json_response.count).to eq(1)
          expect(json_response.first['id']).to eq(operation.external_id)
          expect(json_response.first['partition']).to eq(operation.partition)
          expect(json_response.first['job_class_name']).to eq(operation.job_class_name)
          expect(json_response.first['table_name']).to eq(operation.table_name)
          expect(json_response.first['column_name']).to eq(operation.column_name)
          expect(json_response.first['status']).to eq(operation.status_name.to_s)
        end
      end

      it 'excludes org-scoped workers' do
        org_operation = create(:background_operation_worker)

        get api(path, admin, admin_mode: true)

        ids = json_response.pluck('id')
        expect(ids).not_to include(org_operation.external_id)
      end

      context 'when multiple databases are enabled' do
        let(:database) { :ci }
        let(:schema) { :gitlab_ci }
        let(:ci_model) { Ci::ApplicationRecord }
        let(:params) { { database: database } }

        before do
          skip_if_multiple_databases_not_setup
        end

        context 'when CI database is provided' do
          let(:db_config) do
            instance_double(ActiveRecord::DatabaseConfigurations::HashConfig, name: 'fake_db', database: 'db')
          end

          let(:default_model) { ActiveRecord::Base }
          let(:base_models) { { 'fake_db' => default_model, database.to_s => ci_model }.with_indifferent_access }

          it "uses CI database connection" do
            allow(Gitlab::Database).to receive_messages(
              db_config_for_connection: db_config,
              database_base_models: base_models
            )

            expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(ci_model.connection).and_yield

            get api(path, admin, admin_mode: true), params: params
          end

          context 'when the database name does not exist' do
            let(:database) { :wrong_database }

            it 'returns bad request', :aggregate_failures do
              get api(path, admin, admin_mode: true), params: params

              expect(response).to have_gitlab_http_status(:bad_request)
              expect(response.body).to include('database does not have a valid value')
            end
          end

          it 'returns CI database records' do
            skip_if_multiple_databases_not_setup(database)

            ci_operation = Gitlab::Database::SharedModel.using_connection(ci_model.connection) do
              create(:background_operation_worker_cell_local, :active, gitlab_schema: schema)
            end

            get api(path, admin, admin_mode: true), params: params

            aggregate_failures "testing response" do
              expect(json_response.count).to eq(1)
              expect(json_response.first['id']).to eq(ci_operation.external_id)
              expect(json_response.first['job_class_name']).to eq(ci_operation.job_class_name)
              expect(json_response.first['table_name']).to eq(ci_operation.table_name)
              expect(json_response.first['column_name']).to eq(ci_operation.column_name)
              expect(json_response.first['status']).to eq(ci_operation.status_name.to_s)
            end
          end
        end
      end

      context 'when filtering by job class name' do
        let!(:my_job) { create(:background_operation_worker_cell_local, job_class_name: 'MyJob') }

        let(:params) { { job_class_name: 'MyJob' } }

        it 'returns only relevant records' do
          get api(path, admin, admin_mode: true), params: params

          expect(json_response.count).to eq(1)
          expect(json_response.first['id']).to eq(my_job.external_id)
        end
      end
    end
  end

  describe 'PUT /admin/batched_background_operations/:id/stop' do
    let(:operation) { create(:background_operation_worker_cell_local, :active) }
    let(:params) { {} }
    let(:path) { "/admin/batched_background_operations/#{operation.id}/stop" }

    it_behaves_like "PUT request permissions for admin mode"

    it_behaves_like 'authorizing granular token permissions', :stop_batched_background_operation do
      let(:boundary_object) { :instance }
      let(:user) { admin }
      let(:request) do
        put api(path, personal_access_token: pat), params: params
      end
    end

    subject(:stop) do
      put api(path, admin, admin_mode: true), params: params
    end

    context 'when is an admin user' do
      it 'stops the batched background operation' do
        stop

        aggregate_failures "testing response" do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq(operation.external_id)
          expect(json_response['status']).to eq('stopped')
        end
      end

      context 'when the operation does not exist' do
        it 'returns not found' do
          put api("/admin/batched_background_operations/#{non_existing_record_id}/stop", admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the operation cannot be stopped' do
        let(:operation) { create(:background_operation_worker_cell_local, :finished) }

        it 'returns 422', :aggregate_failures do
          stop

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to include('You can stop only')
        end
      end

      context 'when multiple databases are enabled' do
        let(:ci_model) { Ci::ApplicationRecord }
        let(:params) { { database: :ci } }

        before do
          skip_if_multiple_databases_not_setup(:ci)
        end

        it 'uses the correct connection' do
          expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(ci_model.connection).and_yield

          stop
        end
      end

      context 'when the database name does not exist' do
        let(:params) { { database: :wrong_database } }

        it 'returns bad request', :aggregate_failures do
          stop

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body).to include('database does not have a valid value')
        end
      end
    end
  end

  describe 'PUT /admin/batched_background_operations/:id/restart' do
    let(:operation) { create(:background_operation_worker_cell_local, :stopped) }
    let(:params) { {} }
    let(:path) { "/admin/batched_background_operations/#{operation.id}/restart" }

    it_behaves_like "PUT request permissions for admin mode"

    it_behaves_like 'authorizing granular token permissions', :restart_batched_background_operation do
      let(:boundary_object) { :instance }
      let(:user) { admin }
      let(:request) do
        put api(path, personal_access_token: pat), params: params
      end
    end

    subject(:restart) do
      put api(path, admin, admin_mode: true), params: params
    end

    context 'when is an admin user' do
      it 'restarts the batched background operation' do
        restart

        aggregate_failures "testing response" do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response['id']).to eq(operation.external_id)
          expect(json_response['status']).to eq('active')
        end
      end

      context 'when the operation does not exist' do
        it 'returns not found' do
          put api("/admin/batched_background_operations/#{non_existing_record_id}/restart", admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end

      context 'when the operation is not stopped' do
        let(:operation) { create(:background_operation_worker_cell_local, :active) }

        it 'returns 422', :aggregate_failures do
          restart

          expect(response).to have_gitlab_http_status(:unprocessable_entity)
          expect(json_response['message']).to include('You can restart only')
        end
      end

      context 'when multiple databases are enabled' do
        let(:ci_model) { Ci::ApplicationRecord }
        let(:params) { { database: :ci } }

        before do
          skip_if_multiple_databases_not_setup(:ci)
        end

        it 'uses the correct connection' do
          expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(ci_model.connection).and_yield

          restart
        end
      end

      context 'when the database name does not exist' do
        let(:params) { { database: :wrong_database } }

        it 'returns bad request', :aggregate_failures do
          restart

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body).to include('database does not have a valid value')
        end
      end
    end
  end
end
