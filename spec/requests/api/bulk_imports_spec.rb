# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::BulkImports do
  let_it_be(:user) { create(:user) }
  let_it_be(:import_1) { create(:bulk_import, user: user) }
  let_it_be(:import_2) { create(:bulk_import, user: user) }
  let_it_be(:entity_1) { create(:bulk_import_entity, bulk_import: import_1) }
  let_it_be(:entity_2) { create(:bulk_import_entity, bulk_import: import_1) }
  let_it_be(:entity_3) { create(:bulk_import_entity, bulk_import: import_2) }
  let_it_be(:failure_3) { create(:bulk_import_failure, entity: entity_3) }

  describe 'GET /bulk_imports' do
    it 'returns a list of bulk imports authored by the user' do
      get api('/bulk_imports', user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to contain_exactly(import_1.id, import_2.id)
    end
  end

  describe 'POST /bulk_imports' do
    it 'starts a new migration' do
      post api('/bulk_imports', user), params: {
        configuration: {
          url: 'http://gitlab.example',
          access_token: 'access_token'
        },
        entities: [
          source_type: 'group_entity',
          source_full_path: 'full_path',
          destination_name: 'destination_name',
          destination_namespace: 'destination_namespace'
        ]
      }

      expect(response).to have_gitlab_http_status(:created)

      expect(json_response['status']).to eq('created')
    end

    context 'when provided url is blocked' do
      it 'returns blocked url error' do
        post api('/bulk_imports', user), params: {
          configuration: {
            url: 'url',
            access_token: 'access_token'
          },
          entities: [
            source_type: 'group_entity',
            source_full_path: 'full_path',
            destination_name: 'destination_name',
            destination_namespace: 'destination_namespace'
          ]
        }

        expect(response).to have_gitlab_http_status(:unprocessable_entity)

        expect(json_response['message']).to eq('Validation failed: Url is blocked: Only allowed schemes are http, https')
      end
    end
  end

  describe 'GET /bulk_imports/entities' do
    it 'returns a list of all import entities authored by the user' do
      get api('/bulk_imports/entities', user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to contain_exactly(entity_1.id, entity_2.id, entity_3.id)
    end
  end

  describe 'GET /bulk_imports/:id' do
    it 'returns specified bulk import' do
      get api("/bulk_imports/#{import_1.id}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(import_1.id)
    end
  end

  describe 'GET /bulk_imports/:id/entities' do
    it 'returns specified bulk import entities with failures' do
      get api("/bulk_imports/#{import_2.id}/entities", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to contain_exactly(entity_3.id)
      expect(json_response.first['failures'].first['exception_class']).to eq(failure_3.exception_class)
    end
  end

  describe 'GET /bulk_imports/:id/entities/:entity_id' do
    it 'returns specified bulk import entity' do
      get api("/bulk_imports/#{import_1.id}/entities/#{entity_2.id}", user)

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(entity_2.id)
    end
  end

  context 'when user is unauthenticated' do
    it 'returns 401' do
      get api('/bulk_imports', nil)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end
end
