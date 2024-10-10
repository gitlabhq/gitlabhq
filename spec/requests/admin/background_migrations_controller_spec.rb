# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::BackgroundMigrationsController, :enable_admin_mode, feature_category: :database do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'GET #show' do
    context 'when the migration is valid' do
      let(:migration) { create(:batched_background_migration) }
      let!(:failed_job) { create(:batched_background_migration_job, :failed, batched_migration: migration) }

      it 'fetches the migration' do
        get admin_background_migration_path(migration)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'returns failed jobs' do
        get admin_background_migration_path(migration)

        expect(assigns(:failed_jobs)).to match_array([failed_job])
      end
    end

    context 'when the migration does not exist' do
      let(:invalid_migration) { non_existing_record_id }

      it 'returns not found' do
        get admin_background_migration_path(invalid_migration)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #index' do
    let(:default_model) { ActiveRecord::Base }
    let(:db_config) { instance_double(ActiveRecord::DatabaseConfigurations::HashConfig, name: 'fake_db', database: 'db') }

    before do
      allow(Gitlab::Database).to receive(:db_config_for_connection).and_return(db_config)
      allow(Gitlab::Database).to receive(:database_base_models).and_return(base_models)
    end

    let!(:main_database_migration) { create(:batched_background_migration, :active) }

    context 'when no database is provided' do
      let(:base_models) { { 'fake_db' => default_model }.with_indifferent_access }

      before do
        stub_const('Gitlab::Database::MAIN_DATABASE_NAME', 'fake_db')
      end

      it 'uses the default connection' do
        expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(default_model.connection).and_yield

        get admin_background_migrations_path
      end

      it 'returns default database records' do
        get admin_background_migrations_path

        expect(assigns(:migrations)).to match_array([main_database_migration])
      end

      context 'for finalizing tab' do
        let!(:finalizing_migration) { create(:batched_background_migration, :finalizing) }

        it 'returns only finalizing migration' do
          get admin_background_migrations_path(tab: 'finalizing')

          expect(Gitlab::Database::BackgroundMigration::BatchedMigration.queued).not_to be_empty
          expect(assigns(:migrations)).to match_array(Array.wrap(finalizing_migration))
        end
      end
    end

    context 'when multiple database is enabled', :add_ci_connection do
      let(:base_models) { { 'fake_db' => default_model, 'ci' => ci_model }.with_indifferent_access }
      let(:ci_model) { Ci::ApplicationRecord }

      context 'when CI database is provided' do
        it "uses CI database connection" do
          expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(ci_model.connection).and_yield

          get admin_background_migrations_path, params: { database: 'ci' }
        end

        it 'returns CI database records' do
          # If we only have one DB we'll see both migrations
          skip_if_multiple_databases_not_setup(:ci)

          ci_database_migration = Gitlab::Database::SharedModel.using_connection(ci_model.connection) { create(:batched_background_migration, :active) }

          get admin_background_migrations_path, params: { database: 'ci' }

          expect(assigns(:migrations)).to match_array([ci_database_migration])
          expect(assigns(:migrations)).not_to include(main_database_migration)
        end
      end
    end
  end

  describe 'POST #retry' do
    let(:migration) { create(:batched_background_migration, :failed) }
    let(:job_class) { Gitlab::BackgroundMigration::CopyColumnUsingBackgroundMigrationJob }

    before do
      create(:batched_background_migration_job, :failed, batched_migration: migration, batch_size: 10, min_value: 6, max_value: 15, attempts: 3)

      allow_next_instance_of(Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy) do |batch_class|
        allow(batch_class).to receive(:next_batch).with(
          anything,
          anything,
          batch_min_value: 6,
          batch_size: 5,
          job_arguments: migration.job_arguments,
          job_class: job_class
        ).and_return([6, 10])
      end
    end

    subject(:retry_migration) { post retry_admin_background_migration_path(migration) }

    it 'redirects the user to the admin migrations page' do
      retry_migration

      expect(response).to redirect_to(admin_background_migrations_path)
    end

    it 'retries the migration' do
      retry_migration

      expect(migration.reload.status_name).to be :active
    end

    context 'when the migration is not failed' do
      let(:migration) { create(:batched_background_migration, :paused) }

      it 'keeps the same migration status' do
        expect { retry_migration }.not_to change { migration.reload.status }
      end
    end
  end
end
