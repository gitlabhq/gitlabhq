# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::BatchedJobsController, :enable_admin_mode, feature_category: :database do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe 'GET #show' do
    let(:main_database_job) { create(:batched_background_migration_job) }
    let(:default_model) { ActiveRecord::Base }

    it 'fetches the job' do
      get admin_background_migration_batched_job_path(main_database_job.batched_migration, main_database_job)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'uses the default connection' do
      expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(default_model.connection).and_yield

      get admin_background_migration_batched_job_path(main_database_job.batched_migration, main_database_job)
    end

    it 'returns a default database record' do
      get admin_background_migration_batched_job_path(main_database_job.batched_migration, main_database_job)

      expect(assigns(:job)).to eql(main_database_job)
    end

    context 'when the job does not exist' do
      let(:invalid_job) { non_existing_record_id }

      it 'returns not found' do
        get admin_background_migration_batched_job_path(main_database_job.batched_migration, invalid_job)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when multiple database is enabled', :add_ci_connection do
      let(:base_models) { { 'main' => default_model, 'ci' => ci_model }.with_indifferent_access }
      let(:ci_model) { Ci::ApplicationRecord }

      before do
        allow(Gitlab::Database).to receive(:database_base_models).and_return(base_models)
      end

      context 'when CI database is provided' do
        it "uses CI database connection" do
          expect(Gitlab::Database::SharedModel).to receive(:using_connection).with(ci_model.connection).and_yield

          get admin_background_migration_batched_job_path(main_database_job.batched_migration, main_database_job,
            database: 'ci')
        end

        it 'returns a CI database record' do
          ci_database_job = Gitlab::Database::SharedModel.using_connection(ci_model.connection) do
            create(:batched_background_migration_job, :failed)
          end

          get admin_background_migration_batched_job_path(ci_database_job.batched_migration,
            ci_database_job, database: 'ci')

          expect(assigns(:job)).to eql(ci_database_job)
          expect(assigns(:job)).not_to eql(main_database_job)
        end
      end
    end
  end
end
