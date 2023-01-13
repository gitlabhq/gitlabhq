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

  before do
    stub_application_setting(bulk_import_enabled: true)
  end

  shared_examples 'disabled feature' do
    it 'returns 404' do
      stub_application_setting(bulk_import_enabled: false)

      request

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe 'GET /bulk_imports' do
    let(:request) { get api('/bulk_imports', user), params: params }
    let(:params) { {} }

    it 'returns a list of bulk imports authored by the user' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to contain_exactly(import_1.id, import_2.id)
    end

    context 'sort parameter' do
      it 'sorts by created_at descending by default' do
        request

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.pluck('id')).to eq([import_2.id, import_1.id])
      end

      context 'when explicitly specified' do
        context 'when descending' do
          let(:params) { { sort: 'desc' } }

          it 'sorts by created_at descending' do
            request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.pluck('id')).to match_array([import_2.id, import_1.id])
          end
        end

        context 'when ascending' do
          let(:params) { { sort: 'asc' } }

          it 'sorts by created_at ascending when explicitly specified' do
            request

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.pluck('id')).to match_array([import_1.id, import_2.id])
          end
        end
      end
    end

    include_examples 'disabled feature'
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

    shared_examples 'starting a new migration' do
      let(:request) { post api('/bulk_imports', user), params: params }
      let(:params) do
        {
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
      end

      it 'starts a new migration' do
        request

        expect(response).to have_gitlab_http_status(:created)

        expect(json_response['status']).to eq('created')
      end

      describe 'migrate projects flag' do
        context 'when true' do
          it 'sets true' do
            params[:entities][0][:migrate_projects] = true

            request

            expect(user.bulk_imports.last.entities.pluck(:migrate_projects)).to contain_exactly(true)
          end
        end

        context 'when false' do
          it 'sets false' do
            params[:entities][0][:migrate_projects] = false

            request

            expect(user.bulk_imports.last.entities.pluck(:migrate_projects)).to contain_exactly(false)
          end
        end

        context 'when unspecified' do
          it 'sets true' do
            request

            expect(user.bulk_imports.last.entities.pluck(:migrate_projects)).to contain_exactly(true)
          end
        end
      end
    end

    include_examples 'starting a new migration' do
      let(:destination_param) { { destination_slug: 'destination_slug' } }
    end

    include_examples 'starting a new migration' do
      let(:destination_param) { { destination_name: 'destination_name' } }
    end

    context 'when both destination_name & destination_slug are provided' do
      let(:params) do
        {
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
      end

      it 'returns a mutually exclusive error' do
        request

        expect(response).to have_gitlab_http_status(:bad_request)

        expect(json_response['error']).to eq('entities[0][destination_slug], entities[0][destination_name] are mutually exclusive')
      end
    end

    context 'when neither destination_name nor destination_slug is provided' do
      let(:params) do
        {
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
      end

      it 'returns at_least_one_of error' do
        request

        expect(response).to have_gitlab_http_status(:bad_request)

        expect(json_response['error']).to eq('entities[0][destination_slug], entities[0][destination_name] are missing, at least one parameter must be provided')
      end
    end

    context 'when the source_full_path is invalid' do
      it 'returns invalid error' do
        params[:entities][0][:source_full_path] = 'http://example.com/full_path'

        request
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq("entities[0][source_full_path] must be a relative path and not include protocol, sub-domain, " \
                                             "or domain information. E.g. 'source/full/path' not 'https://example.com/source/full/path'")
      end
    end

    context 'when the destination_namespace is invalid' do
      it 'returns invalid error' do
        params[:entities][0][:destination_namespace] = "?not a destination-namespace"

        request
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to eq("entities[0][destination_namespace] cannot start with a dash or forward slash, " \
                                             "or end with a period or forward slash. It can only contain alphanumeric " \
                                             "characters, periods, underscores, forward slashes and dashes. " \
                                             "E.g. 'destination_namespace' or 'destination/namespace'")
      end
    end

    context 'when the destination_namespace is an empty string' do
      it 'accepts the param and starts a new migration' do
        params[:entities][0][:destination_namespace] = ''

        request
        expect(response).to have_gitlab_http_status(:created)

        expect(json_response['status']).to eq('created')
      end
    end

    context 'when the destination_slug is invalid' do
      it 'returns invalid error' do
        params[:entities][0][:destination_slug] = 'des?tin?atoi-slugg'

        request
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to include("entities[0][destination_slug] cannot start with a dash " \
                                                  "or forward slash, or end with a period or forward slash. " \
                                                  "It can only contain alphanumeric characters, periods, underscores, and dashes. " \
                                                  "E.g. 'destination_namespace' not 'destination/namespace'")
      end
    end

    context 'when provided url is blocked' do
      let(:params) do
        {
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
      end

      it 'returns blocked url error' do
        request

        expect(response).to have_gitlab_http_status(:unprocessable_entity)

        expect(json_response['message']).to eq('Validation failed: Url is blocked: Only allowed schemes are http, https')
      end
    end

    include_examples 'disabled feature'
  end

  describe 'GET /bulk_imports/entities' do
    let(:request) { get api('/bulk_imports/entities', user) }

    it 'returns a list of all import entities authored by the user' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to contain_exactly(entity_1.id, entity_2.id, entity_3.id)
    end

    include_examples 'disabled feature'
  end

  describe 'GET /bulk_imports/:id' do
    let(:request) { get api("/bulk_imports/#{import_1.id}", user) }

    it 'returns specified bulk import' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(import_1.id)
    end

    include_examples 'disabled feature'
  end

  describe 'GET /bulk_imports/:id/entities' do
    let(:request) { get api("/bulk_imports/#{import_2.id}/entities", user) }

    it 'returns specified bulk import entities with failures' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to contain_exactly(entity_3.id)
      expect(json_response.first['failures'].first['exception_class']).to eq(failure_3.exception_class)
    end

    include_examples 'disabled feature'
  end

  describe 'GET /bulk_imports/:id/entities/:entity_id' do
    let(:request) { get api("/bulk_imports/#{import_1.id}/entities/#{entity_2.id}", user) }

    it 'returns specified bulk import entity' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(entity_2.id)
    end

    include_examples 'disabled feature'
  end

  context 'when user is unauthenticated' do
    it 'returns 401' do
      get api('/bulk_imports', nil)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end
end
