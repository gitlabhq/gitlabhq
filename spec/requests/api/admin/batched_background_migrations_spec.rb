# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::BatchedBackgroundMigrations do
  let(:admin) { create(:admin) }
  let(:unauthorized_user) { create(:user) }

  describe 'GET /admin/batched_background_migrations/:id' do
    let!(:migration) { create(:batched_background_migration, :paused) }
    let(:database) { :main }

    subject(:show_migration) do
      get api("/admin/batched_background_migrations/#{migration.id}", admin), params: { database: database }
    end

    it 'fetches the batched background migration' do
      show_migration

      aggregate_failures "testing response" do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(migration.id)
        expect(json_response['status']).to eq('paused')
        expect(json_response['job_class_name']).to eq(migration.job_class_name)
        expect(json_response['progress']).to be_zero
      end
    end

    context 'when the batched background migration does not exist' do
      let(:params) { { database: database } }

      it 'returns 404' do
        put api("/admin/batched_background_migrations/#{non_existing_record_id}", admin), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when multiple database is enabled' do
      before do
        skip_if_multiple_databases_not_setup
      end

      let(:ci_model) { Ci::ApplicationRecord }
      let(:database) { :ci }

      it 'uses the correct connection' do
        expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(ci_model.connection).and_yield

        show_migration
      end
    end

    context 'when authenticated as a non-admin user' do
      it 'returns 403' do
        get api("/admin/batched_background_migrations/#{migration.id}", unauthorized_user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'GET /admin/batched_background_migrations' do
    let!(:migration) { create(:batched_background_migration) }

    context 'when is an admin user' do
      it 'returns batched background migrations' do
        get api('/admin/batched_background_migrations', admin)

        aggregate_failures "testing response" do
          expect(response).to have_gitlab_http_status(:ok)
          expect(json_response.count).to eq(1)
          expect(json_response.first['id']).to eq(migration.id)
          expect(json_response.first['job_class_name']).to eq(migration.job_class_name)
          expect(json_response.first['table_name']).to eq(migration.table_name)
          expect(json_response.first['status']).to eq(migration.status_name.to_s)
          expect(json_response.first['progress']).to be_zero
        end
      end

      context 'when multiple database is enabled', :add_ci_connection do
        let(:database) { :ci }
        let(:schema) { :gitlab_ci }
        let(:ci_model) { Ci::ApplicationRecord }

        context 'when CI database is provided' do
          let(:db_config) { instance_double(ActiveRecord::DatabaseConfigurations::HashConfig, name: 'fake_db') }
          let(:default_model) { ActiveRecord::Base }
          let(:base_models) { { 'fake_db' => default_model, 'ci' => ci_model }.with_indifferent_access }

          it "uses CI database connection" do
            allow(Gitlab::Database).to receive(:db_config_for_connection).and_return(db_config)
            allow(Gitlab::Database).to receive(:database_base_models).and_return(base_models)

            expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(ci_model.connection).and_yield

            get api('/admin/batched_background_migrations', admin), params: { database: :ci }
          end

          it 'returns CI database records' do
            # If we only have one DB we'll see both migrations
            skip_if_multiple_databases_not_setup

            ci_database_migration = Gitlab::Database::SharedModel.using_connection(ci_model.connection) do
              create(:batched_background_migration, :active, gitlab_schema: schema)
            end

            get api('/admin/batched_background_migrations', admin), params: { database: :ci }

            aggregate_failures "testing response" do
              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response.count).to eq(1)
              expect(json_response.first['id']).to eq(ci_database_migration.id)
              expect(json_response.first['job_class_name']).to eq(ci_database_migration.job_class_name)
              expect(json_response.first['table_name']).to eq(ci_database_migration.table_name)
              expect(json_response.first['status']).to eq(ci_database_migration.status_name.to_s)
              expect(json_response.first['progress']).to be_zero
            end
          end
        end
      end
    end

    context 'when authenticated as a non-admin user' do
      it 'returns 403' do
        get api('/admin/batched_background_migrations', unauthorized_user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'PUT /admin/batched_background_migrations/:id/resume' do
    let!(:migration) { create(:batched_background_migration, :paused) }
    let(:database) { :main }

    subject(:resume) do
      put api("/admin/batched_background_migrations/#{migration.id}/resume", admin), params: { database: database }
    end

    it 'pauses the batched background migration' do
      resume

      aggregate_failures "testing response" do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(migration.id)
        expect(json_response['status']).to eq('active')
      end
    end

    context 'when the batched background migration does not exist' do
      let(:params) { { database: database } }

      it 'returns 404' do
        put api("/admin/batched_background_migrations/#{non_existing_record_id}/resume", admin), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the migration is not paused' do
      let!(:migration) { create(:batched_background_migration, :failed) }
      let(:params) { { database: database } }

      it 'returns 422' do
        put api("/admin/batched_background_migrations/#{migration.id}/resume", admin), params: params

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'when multiple database is enabled' do
      let(:ci_model) { Ci::ApplicationRecord }
      let(:database) { :ci }

      before do
        skip_if_multiple_databases_not_setup
      end

      it 'uses the correct connection' do
        expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(ci_model.connection).and_yield

        resume
      end
    end

    context 'when authenticated as a non-admin user' do
      it 'returns 403' do
        put api("/admin/batched_background_migrations/#{migration.id}/resume", unauthorized_user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end

  describe 'PUT /admin/batched_background_migrations/:id/pause' do
    let!(:migration) { create(:batched_background_migration, :active) }

    it 'pauses the batched background migration' do
      put api("/admin/batched_background_migrations/#{migration.id}/pause", admin), params: { database: :main }

      aggregate_failures "testing response" do
        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['id']).to eq(migration.id)
        expect(json_response['status']).to eq('paused')
      end
    end

    context 'when the batched background migration does not exist' do
      let(:params) { { database: :main } }

      it 'returns 404' do
        put api("/admin/batched_background_migrations/#{non_existing_record_id}/pause", admin), params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the migration is not active' do
      let!(:migration) { create(:batched_background_migration, :failed) }
      let(:params) { { database: :main } }

      it 'returns 422' do
        put api("/admin/batched_background_migrations/#{migration.id}/pause", admin), params: params

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'when multiple database is enabled' do
      let(:ci_model) { Ci::ApplicationRecord }

      before do
        skip_if_multiple_databases_not_setup
      end

      it 'uses the correct connection' do
        expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(ci_model.connection).and_yield

        put api("/admin/batched_background_migrations/#{migration.id}/pause", admin), params: { database: :ci }
      end
    end

    context 'when authenticated as a non-admin user' do
      it 'returns 403' do
        put api("/admin/batched_background_migrations/#{non_existing_record_id}/pause", unauthorized_user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
