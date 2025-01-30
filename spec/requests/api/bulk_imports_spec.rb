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
  let_it_be(:tracker_1) do
    create(
      :bulk_import_tracker,
      entity: entity_1,
      relation: 'BulkImports::Common::Pipelines::LabelsPipeline',
      source_objects_count: 3,
      fetched_objects_count: 2,
      imported_objects_count: 1
    )
  end

  let_it_be(:tracker_2) do
    create(
      :bulk_import_tracker,
      entity: entity_2,
      relation: 'BulkImports::Common::Pipelines::MilestonesPipeline',
      source_objects_count: 5,
      fetched_objects_count: 4,
      imported_objects_count: 3
    )
  end

  let_it_be(:tracker_3) do
    create(
      :bulk_import_tracker,
      entity: entity_3,
      relation: 'BulkImports::Common::Pipelines::BoardsPipeline',
      source_objects_count: 10,
      fetched_objects_count: 9,
      imported_objects_count: 8
    )
  end

  before do
    stub_application_setting(bulk_import_enabled: true)

    allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(false)
  end

  shared_examples 'disabled feature' do
    before do
      stub_application_setting(bulk_import_enabled: false)
    end

    it_behaves_like '404 response' do
      let(:message) { '404 Not Found' }
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

    it_behaves_like 'disabled feature'
  end

  describe 'POST /bulk_imports' do
    let_it_be(:destination_namespace) { create(:group) }

    let(:request) { post api('/bulk_imports', user), params: params }
    let(:destination_param) { { destination_slug: 'destination_slug' } }
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
            destination_namespace: destination_namespace.path
          }.merge(destination_param)
        ]
      }
    end

    let(:source_entity_type) { BulkImports::CreateService::ENTITY_TYPES_MAPPING.fetch(params[:entities][0][:source_type]) }
    let(:source_entity_identifier) { '165' }

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

      allow_next_instance_of(BulkImports::Clients::Graphql) do |client|
        allow(client).to receive(:parse)
        allow(client).to receive(:execute).and_return(
          instance_double(GraphQL::Client::Response, original_hash: { 'data' => { 'group' => { 'id' => "gid://gitlab/Group/#{source_entity_identifier}" } } })
        )
      end

      stub_request(:get, "http://gitlab.example/api/v4/#{source_entity_type}/#{source_entity_identifier}/export_relations/status?page=1&per_page=30&private_token=access_token")
        .to_return(status: 200, body: "", headers: {})

      destination_namespace.add_owner(user)
    end

    shared_examples 'starting a new migration' do
      it 'starts a new migration' do
        expect { request }.to change { BulkImports::Entity.count }

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

      describe 'migrate memberships flag' do
        context 'when true' do
          it 'sets true' do
            params[:entities][0][:migrate_memberships] = true

            request

            expect(user.bulk_imports.last.entities.pluck(:migrate_memberships)).to contain_exactly(true)
          end
        end

        context 'when false' do
          it 'sets false' do
            params[:entities][0][:migrate_memberships] = false

            request

            expect(user.bulk_imports.last.entities.pluck(:migrate_memberships)).to contain_exactly(false)
          end
        end

        context 'when unspecified' do
          it 'sets true' do
            request

            expect(user.bulk_imports.last.entities.pluck(:migrate_memberships)).to contain_exactly(true)
          end
        end
      end

      context 'when entities do not specify a namespace', :with_current_organization do
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
                destination_namespace: ''
              }.merge(destination_param)
            ]
          }
        end

        it 'uses the current organization' do
          expect { request }.to change { BulkImports::Entity.count }

          expect(BulkImports::Entity.last.organization).to eq(current_organization)

          expect(response).to have_gitlab_http_status(:created)

          expect(json_response['status']).to eq('created')
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
              destination_namespace: destination_namespace.path
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
                                             "or domain information. For example, 'source/full/path' not 'https://example.com/source/full/path'")
      end
    end

    context 'when the destination_namespace does not exist' do
      it 'returns invalid error' do
        params[:entities][0][:destination_namespace] = "invalid-destination-namespace"

        request
        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(json_response['message']).to eq("Import failed. Destination 'invalid-destination-namespace' is invalid, or you don't have permission.")
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

    context 'when the destination_namespace is invalid' do
      it 'returns invalid error' do
        params[:entities][0][:destination_namespace] = 'dest?nation-namespace'

        request
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to include('entities[0][destination_namespace] must be a relative path ' \
                                                  'and not include protocol, sub-domain, or domain information. ' \
                                                  "For example, 'destination/full/path' not " \
                                                  "'https://example.com/destination/full/path'")
      end
    end

    context 'when the destination_slug is invalid' do
      it 'returns invalid error' do
        params[:entities][0][:destination_slug] = 'des?tin?atoi-slugg'

        request
        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['error']).to include("entities[0][destination_slug] can only include " \
                                                  "non-accented letters, digits, '_', '-' and '.'. " \
                                                  "It must not start with '-', '_', or '.', nor end with '-', '_', '.', '.git', or '.atom'. " \
                                                  "For example, 'destination_namespace' not 'destination/namespace'")
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

      it 'returns not accessible message in the error', :aggregate_failures do
        stub_request(:get, "http://gitlab.example/api/v4/#{source_entity_type}/#{source_entity_identifier}/export_relations/status?page=1&per_page=30&private_token=token")
          .to_return(status: 403, body: "Forbidden 403", headers: {})

        request

        expect(json_response['message']).to eq("Import failed. You don't have permission to export 'full_path'.")
      end
    end

    context 'when resource is not found on source instance' do
      let(:params) do
        {
          configuration: {
            url: 'http://gitlab.example',
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

      before do
        allow_next_instance_of(BulkImports::Clients::Graphql) do |client|
          allow(client).to receive(:parse)
          allow(client).to receive(:execute).and_return(
            instance_double(GraphQL::Client::Response, original_hash: { 'data' => { 'group' => nil } })
          )
        end
      end

      it 'returns not found message', :aggregate_failures do
        request

        expect(json_response['message']).to eq("Import failed. 'full_path' not found.")
      end
    end

    context 'when source instance setting is disabled' do
      let(:params) do
        {
          configuration: {
            url: 'http://gitlab.example',
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

      it 'returns disabled instance error message', :aggregate_failures do
        stub_request(:get, "http://gitlab.example/api/v4/#{source_entity_type}/#{source_entity_identifier}/export_relations/status?page=1&per_page=30&private_token=access_token")
          .to_return(status: 404, body: "Unsuccessful response 404", headers: {})

        request

        expect(json_response['message']).to include("Migration by direct transfer disabled on source or destination instance. " \
                                                    "Ask an administrator to enable it on both instances and try again.")
      end
    end

    it_behaves_like 'disabled feature'

    context 'when request exceeds rate limits' do
      it 'prevents user from starting a new migration' do
        allow(::Gitlab::ApplicationRateLimiter).to receive(:throttled?).and_return(true)

        request

        expect(response).to have_gitlab_http_status(:too_many_requests)
        expect(json_response['message']['error']).to eq('This endpoint has been requested too many times. Try again later.')
      end
    end
  end

  describe 'GET /bulk_imports/entities' do
    let(:request) { get api('/bulk_imports/entities', user) }

    it 'returns a list of all import entities authored by the user' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to contain_exactly(entity_1.id, entity_2.id, entity_3.id)
    end

    it 'includes entity stats' do
      request

      expect(json_response.pluck('stats')).to contain_exactly(
        { 'labels' => { 'source' => 3, 'fetched' => 2, 'imported' => 1 } },
        { 'milestones' => { 'source' => 5, 'fetched' => 4, 'imported' => 3 } },
        { 'boards' => { 'source' => 10, 'fetched' => 9, 'imported' => 8 } }
      )
    end

    it_behaves_like 'disabled feature'
  end

  describe 'GET /bulk_imports/:id' do
    let(:request) { get api("/bulk_imports/#{import_1.id}", user) }

    it 'returns specified bulk import' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(import_1.id)
    end

    it_behaves_like 'disabled feature'
  end

  describe 'GET /bulk_imports/:id/entities' do
    let(:request) { get api("/bulk_imports/#{import_2.id}/entities", user) }

    it 'returns specified bulk import entities with failures' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.pluck('id')).to contain_exactly(entity_3.id)
      expect(json_response.first['failures'].first['exception_message']).to eq(failure_3.exception_message)
    end

    it 'includes entity stats' do
      request

      expect(json_response.pluck('stats')).to contain_exactly(
        { 'boards' => { 'source' => 10, 'fetched' => 9, 'imported' => 8 } }
      )
    end

    it_behaves_like 'disabled feature'
  end

  describe 'GET /bulk_imports/:id/entities/:entity_id' do
    let(:request) { get api("/bulk_imports/#{import_1.id}/entities/#{entity_2.id}", user) }

    it 'returns specified bulk import entity' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['id']).to eq(entity_2.id)
    end

    it 'includes entity stats' do
      request

      expect(json_response['stats']).to eq({ 'milestones' => { 'source' => 5, 'fetched' => 4, 'imported' => 3 } })
    end

    it_behaves_like 'disabled feature'
  end

  context 'when user is unauthenticated' do
    it 'returns 401' do
      get api('/bulk_imports', nil)

      expect(response).to have_gitlab_http_status(:unauthorized)
    end
  end

  describe 'GET /bulk_imports/:id/entities/:entity_id/failures' do
    let(:request) { get api("/bulk_imports/#{import_2.id}/entities/#{entity_3.id}/failures", user) }

    it 'returns specified entity failures' do
      request

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response.first['exception_message']).to eq(failure_3.exception_message)
    end

    it_behaves_like 'disabled feature'
  end

  describe 'POST /bulk_imports/:id/cancel' do
    let(:import) { create(:bulk_import, user: user) }

    context 'when user is canceling their own migration' do
      it 'cancels the migration and returns 200' do
        post api("/bulk_imports/#{import.id}/cancel", user)

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['status']).to eq('canceled')
      end
    end

    context 'when user is trying to cancel a migration they have not created' do
      it 'returns an error' do
        import = create(:bulk_import)

        post api("/bulk_imports/#{import.id}/cancel", user)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    context 'when authenticated as admin' do
      let_it_be(:admin) { create(:admin) }

      it 'cancels the migration and returns 200' do
        post api("/bulk_imports/#{import.id}/cancel", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:ok)

        expect(json_response['status']).to eq('canceled')
      end

      context 'when migration could not be found' do
        it 'return 404' do
          post api("/bulk_imports/#{non_existing_record_id}/cancel", admin, admin_mode: true)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end
  end
end
