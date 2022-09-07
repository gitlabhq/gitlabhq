# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::BatchedBackgroundMigrations do
  let(:admin) { create(:admin) }
  let(:unauthorized_user) { create(:user) }

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
end
