# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::BulkImports, feature_category: :importers do
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

    context 'sort parameter' do
      it 'sorts by created_at descending by default' do
        get api('/bulk_imports', user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to eq([import_2.id, import_1.id])
      end

      it 'sorts by created_at descending when explicitly specified' do
        get api('/bulk_imports', user), params: { sort: 'desc' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to eq([import_2.id, import_1.id])
      end

      it 'sorts by created_at ascending when explicitly specified' do
        get api('/bulk_imports', user), params: { sort: 'asc' }

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to eq([import_1.id, import_2.id])
      end
    end
  end

  describe 'POST /bulk_imports' do
    before do
      allow_next_instance_of(BulkImports::Clients::HTTP) do |instance|
        allow(instance)
          .to receive(:instance_version)
          .and_return(
            Gitlab::VersionInfo.new(::BulkImport::MIN_MAJOR_VERSION, ::BulkImport::MIN_MINOR_VERSION_FOR_PROJECT))
        allow(instance)
          .to receive(:instance_enterprise)
          .and_return(false)
      end
    end

    context 'when bulk_import feature flag is disabled' do
      before do
        stub_feature_flags(bulk_import: false)
      end

      it 'returns 404' do
        post api('/bulk_imports', user), params: {}

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    shared_examples 'starting a new migration' do
      it 'starts a new migration' do
        post api('/bulk_imports', user), params: {
          configuration: {
            url: 'http://gitlab.example',
            access_token: 'access_token'
          },
          entities: [
            {
              source_type: 'group_entity',
              source_full_path: 'full_path',
              destination_namespace: 'destination_namespace'
            }.merge(destination_param)
          ]
        }

        expect(response).to have_gitlab_http_status(:created)

        expect(json_response['status']).to eq('created')
      end
    end

    include_examples 'starting a new migration' do
      let(:destination_param) { { destination_slug: 'destination_slug' } }
    end

    include_examples 'starting a new migration' do
      let(:destination_param) { { destination_name: 'destination_name' } }
    end

    context 'when both destination_name & destination_slug are provided' do
      it 'returns a mutually exclusive error' do
        post api('/bulk_imports', user), params: {
          configuration: {
            url: 'http://gitlab.example',
            access_token: 'access_token'
          },
          entities: [
            {
              source_type: 'group_entity',
              source_full_path: 'full_path',
              destination_name: 'destination_name',
              destination_slug: 'destination_slug',
              destination_namespace: 'destination_namespace'
            }
          ]
        }

        expect(response).to have_gitlab_http_status(:bad_request)

        expect(json_response['error']).to eq('entities[0][destination_slug], entities[0][destination_name] are mutually exclusive')
      end
    end

    context 'when neither destination_name nor destination_slug is provided' do
      it 'returns at_least_one_of error' do
        post api('/bulk_imports', user), params: {
          configuration: {
            url: 'http://gitlab.example',
            access_token: 'access_token'
          },
          entities: [
            {
              source_type: 'group_entity',
              source_full_path: 'full_path',
              destination_namespace: 'destination_namespace'
            }
          ]
        }

        expect(response).to have_gitlab_http_status(:bad_request)

        expect(json_response['error']).to eq('entities[0][destination_slug], entities[0][destination_name] are missing, at least one parameter must be provided')
      end
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
            destination_slug: 'destination_slug',
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
