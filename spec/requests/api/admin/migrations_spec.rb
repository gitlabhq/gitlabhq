# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::Migrations, feature_category: :database do
  let(:admin) { create(:admin) }

  describe 'POST /admin/migrations/:version/mark' do
    let(:database) { :main }
    let(:params) { { database: database } }
    let(:connection) { ApplicationRecord.connection }
    let(:path) { "/admin/migrations/#{version}/mark" }
    let(:version) { 1 }

    subject(:mark) do
      post api(path, admin, admin_mode: true), params: params
    end

    context 'when the migration exists' do
      before do
        double = instance_double(
          Database::MarkMigrationService,
          execute: ServiceResponse.success)

        allow(Database::MarkMigrationService)
          .to receive(:new)
          .with(connection: connection, version: version)
          .and_return(double)
      end

      it_behaves_like "POST request permissions for admin mode"

      it 'marks the migration as successful' do
        mark

        expect(response).to have_gitlab_http_status(:created)
      end
    end

    context 'when the migration does not exist' do
      let(:version) { 123 }

      it 'returns 404' do
        mark

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when the migration was already executed' do
      let(:version) { connection.migration_context.current_version }

      it 'returns 422' do
        mark

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
      end
    end

    context 'when multiple database is enabled' do
      let(:ci_model) { Ci::ApplicationRecord }
      let(:database) { :ci }

      before do
        skip_if_multiple_databases_not_setup(:ci)
      end

      it 'uses the correct connection' do
        expect(Database::MarkMigrationService)
          .to receive(:new)
          .with(connection: ci_model.connection, version: version)
          .and_call_original

        mark
      end

      context 'when the database name does not exist' do
        let(:database) { :wrong_database }

        it 'returns bad request', :aggregate_failures do
          mark

          expect(response).to have_gitlab_http_status(:bad_request)
          expect(response.body).to include('database does not have a valid value')
        end
      end
    end
  end
end
