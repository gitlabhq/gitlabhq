# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::CreateService, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include GraphqlHelpers

  let(:user) { create(:user) }
  let(:fallback_organization) { create(:organization) }
  let(:credentials) { { url: 'http://gitlab.example', access_token: 'token' } }
  let(:destination_group) { create(:group, path: 'destination1') }
  let(:migrate_projects) { true }
  let(:migrate_memberships) { true }
  let_it_be(:parent_group) { create(:group, path: 'parent-group') }
  # note: destination_name and destination_slug are currently interchangable so we need to test for both possibilities
  let(:params) do
    [
      {
        source_type: 'group_entity',
        source_full_path: 'full/path/to/group1',
        destination_slug: 'destination-group-1',
        destination_namespace: 'parent-group',
        migrate_projects: migrate_projects,
        migrate_memberships: migrate_memberships
      },
      {
        source_type: 'group_entity',
        source_full_path: 'full/path/to/group2',
        destination_name: 'destination-group-2',
        destination_namespace: 'parent-group',
        migrate_projects: migrate_projects,
        migrate_memberships: migrate_memberships
      },
      {
        source_type: 'project_entity',
        source_full_path: 'full/path/to/project1',
        destination_slug: 'destination-project-1',
        destination_namespace: 'parent-group',
        migrate_projects: migrate_projects,
        migrate_memberships: migrate_memberships
      }
    ]
  end

  let(:source_entity_identifier) { ERB::Util.url_encode(params[0][:source_full_path]) }
  let(:source_entity_type) { BulkImports::CreateService::ENTITY_TYPES_MAPPING.fetch(params[0][:source_type]) }

  subject { described_class.new(user, params, credentials, fallback_organization:) }

  describe '#execute' do
    context 'when gitlab version is 15.5 or higher' do
      let(:source_version) { { version: "15.6.0", enterprise: false } }

      context 'when a BulkImports::Error is raised while validating the instance version' do
        before do
          allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
            allow(client)
              .to receive(:validate_instance_version!)
              .and_raise(BulkImports::Error, "This is a BulkImports error.")
          end
        end

        it 'rescues the error and raises a ServiceResponse::Error' do
          result = subject.execute

          expect(result).to be_a(ServiceResponse)
          expect(result).to be_error
          expect(result.message).to eq("This is a BulkImports error.")
        end
      end

      context 'when the resource is not found  while validating the source_full_path' do
        before do
          allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
            allow(client)
              .to receive(:validate_instance_version!)
              .and_return(true)

            allow(client)
              .to receive(:validate_import_scopes!)
              .and_return(true)
          end
        end

        it 'rescues the error and raises a BulkImports::Error' do
          expect_next_instance_of(BulkImports::Clients::Graphql) do |client|
            expect(client)
             .to receive(:execute)
             .and_return(instance_double(GraphQL::Client::Response, original_hash: { 'data' => { 'group' => nil } }))

            expect(client).to receive(:parse)
          end

          result = subject.execute

          expect(result).to be_a(ServiceResponse)
          expect(result).to be_error
          expect(result.message).to eq("Import failed. 'full/path/to/group1' not found.")
        end
      end

      # response when authorize_admin_project in API endpoint fails
      context 'when direct transfer status query returns a 403' do
        before do
          allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
            allow(client).to receive(:validate_instance_version!).and_return(true)
            allow(client).to receive(:validate_import_scopes!).and_return(true)
          end

          allow_next_instance_of(BulkImports::Clients::Graphql) do |client|
            allow(client)
             .to receive(:execute)
             .and_return(instance_double(GraphQL::Client::Response, original_hash: {
               'data' => { 'group' => { 'id' => 'gid://gitlab/Group/165' } }
             }))

            allow(client).to receive(:parse)
          end
        end

        it 'raises a ServiceResponse::Error' do
          stub_request(:get, "http://gitlab.example/api/v4/#{source_entity_type}/165/export_relations/status?page=1&per_page=30&private_token=token")
            .to_return(status: 403)

          result = subject.execute

          expect(result).to be_a(ServiceResponse)
          expect(result).to be_error
          expect(result.message).to eq("Import failed. You don't have permission to export 'full/path/to/group1'.")
        end
      end

      context 'when direct transfer setting query returns a 404' do
        it 'raises a ServiceResponse::Error' do
          allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
            allow(client).to receive(:validate_instance_version!).and_return(true)
            allow(client).to receive(:validate_import_scopes!).and_return(true)
          end

          allow_next_instance_of(BulkImports::Clients::Graphql) do |client|
            allow(client)
             .to receive(:execute)
             .and_return(instance_double(GraphQL::Client::Response, original_hash: {
               'data' => { 'group' => { 'id' => 'gid://gitlab/Group/165' } }
             }))

            allow(client).to receive(:parse)
          end

          stub_request(:get, "http://gitlab.example/api/v4/#{source_entity_type}/165/export_relations/status?page=1&per_page=30&private_token=token")
            .to_return(status: 404)

          result = subject.execute

          expect(result).to be_a(ServiceResponse)
          expect(result).to be_error
          expect(result.message)
            .to eq(
              "Migration by direct transfer disabled on source or destination instance. " \
              "Ask an administrator to enable it on both instances and try again."
            )
        end
      end

      context 'when direct transfer setting query raises any other NetworkError' do
        it 'raises a ServiceResponse::Error' do
          allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
            allow(client).to receive(:validate_instance_version!).and_return(true)
            allow(client).to receive(:validate_import_scopes!).and_return(true)
          end

          allow_next_instance_of(BulkImports::Clients::Graphql) do |client|
            allow(client)
             .to receive(:execute)
             .and_return(instance_double(GraphQL::Client::Response, original_hash: {
               'data' => { 'group' => { 'id' => 'gid://gitlab/Group/165' } }
             }))

            allow(client).to receive(:parse)
          end

          stub_request(:get, "http://gitlab.example/api/v4/#{source_entity_type}/165/export_relations/status?page=1&per_page=30&private_token=token")
            .to_return(status: 408)

          result = subject.execute

          expect(result).to be_a(ServiceResponse)
          expect(result).to be_error
          expect(result.message)
            .to include("Unsuccessful response 408")
        end
      end

      context 'when required scopes are not present' do
        it 'returns ServiceResponse with error if token does not have api scope' do
          allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
            allow(client).to receive(:validate_instance_version!).and_return(true)
            allow(client).to receive(:validate_import_scopes!)
              .and_raise(BulkImports::Error.scope_or_url_validation_failure)
          end

          result = subject.execute

          expect(result).to be_a(ServiceResponse)
          expect(result).to be_error
          expect(result.message)
            .to eq(
              "Check that the source instance base URL and the personal access token meet the necessary requirements."
            )
        end
      end

      context 'when token validation succeeds' do
        before do
          allow(subject).to receive(:validate!).and_return(true)

          allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
            allow(client).to receive(:instance_version).and_return(source_version[:version])
            allow(client).to receive(:instance_enterprise).and_return(false)
          end

          parent_group.add_owner(user)
        end

        it 'creates bulk import' do
          expect { subject.execute }.to change { BulkImport.count }.by(1)

          last_bulk_import = BulkImport.last

          expect(last_bulk_import.user).to eq(user)
          expect(last_bulk_import.source_version).to eq(source_version[:version])
          expect(last_bulk_import.user).to eq(user)
          expect(last_bulk_import.source_enterprise).to eq(false)

          expect_snowplow_event(
            category: 'BulkImports::CreateService',
            action: 'create',
            label: 'bulk_import_group',
            extra: { source_equals_destination: false }
          )

          expect_snowplow_event(
            category: 'BulkImports::CreateService',
            action: 'create',
            label: 'import_access_level',
            user: user,
            extra: { user_role: 'Owner', import_type: 'bulk_import_group' }
          )
        end

        context 'when a destination_namespace is provided' do
          it 'uses the organization of the provided namespace for the bulk import entites' do
            expect { subject.execute }.to change { BulkImports::Entity.count }

            last_bulk_import = BulkImports::Entity.last

            expect(last_bulk_import.organization).to eq(parent_group.organization)
          end
        end

        context 'when no destination_namespace is provided' do
          let(:params) do
            [
              {
                source_type: 'group_entity',
                source_full_path: 'full/path/to/group1',
                destination_slug: 'destination-group-1',
                destination_namespace: '',
                migrate_projects: migrate_projects
              }
            ]
          end

          it 'uses the fallback_organization for the bulk import entites' do
            expect { subject.execute }.to change { BulkImports::Entity.count }

            last_bulk_import = BulkImports::Entity.last

            expect(last_bulk_import.organization).to eq(fallback_organization)
          end

          it 'does not look up the empty namespace' do
            expect(Group).not_to receive(:find_by_full_path).with('')

            subject.execute
          end
        end

        context 'on the same instance' do
          before do
            allow(Settings.gitlab).to receive(:base_url).and_return('http://gitlab.example')
          end

          it 'tracks the same instance migration' do
            expect { subject.execute }.to change { BulkImport.count }.by(1)

            expect_snowplow_event(
              category: 'BulkImports::CreateService',
              action: 'create',
              label: 'bulk_import_group',
              extra: { source_equals_destination: true }
            )
          end
        end

        describe 'projects migration flag' do
          let(:import) { BulkImport.last }

          context 'when false' do
            let(:migrate_projects) { false }

            it 'sets false' do
              subject.execute

              expect(import.entities.pluck(:migrate_projects)).to contain_exactly(false, false, false)
            end
          end

          context 'when true' do
            let(:migrate_projects) { true }

            it 'sets true' do
              subject.execute

              expect(import.entities.pluck(:migrate_projects)).to contain_exactly(true, true, true)
            end
          end

          context 'when nil' do
            let(:migrate_projects) { nil }

            it 'sets true' do
              subject.execute

              expect(import.entities.pluck(:migrate_projects)).to contain_exactly(true, true, true)
            end
          end
        end

        describe 'memberships migration flag' do
          let(:import) { BulkImport.last }

          context 'when false' do
            let(:migrate_memberships) { false }

            it 'sets false' do
              subject.execute

              expect(import.entities.pluck(:migrate_memberships)).to contain_exactly(false, false, false)
            end
          end

          context 'when true' do
            let(:migrate_memberships) { true }

            it 'sets true' do
              subject.execute

              expect(import.entities.pluck(:migrate_memberships)).to contain_exactly(true, true, true)
            end
          end

          context 'when nil' do
            let(:migrate_memberships) { nil }

            it 'sets true' do
              subject.execute

              expect(import.entities.pluck(:migrate_memberships)).to contain_exactly(true, true, true)
            end
          end
        end
      end
    end

    context 'when gitlab version is lower than 15.5' do
      let(:source_version) do
        Gitlab::VersionInfo.new(
          ::BulkImport::MIN_MAJOR_VERSION,
          ::BulkImport::MIN_MINOR_VERSION_FOR_PROJECT
        )
      end

      before do
        allow_next_instance_of(BulkImports::Clients::HTTP) do |instance|
          allow(instance).to receive(:instance_version).and_return(source_version)
          allow(instance).to receive(:instance_enterprise).and_return(false)

          allow_next_instance_of(BulkImports::Clients::Graphql) do |client|
            allow(client)
             .to receive(:execute)
             .and_return(instance_double(GraphQL::Client::Response, original_hash: {
               'data' => { 'group' => { 'id' => 'gid://gitlab/Group/165' } }
             }))

            allow(client).to receive(:parse)
          end

          stub_request(:get, "http://gitlab.example/api/v4/#{source_entity_type}/165/export_relations/status?page=1&per_page=30&private_token=token")
            .to_return(
              status: 200
            )
        end

        allow_next_instance_of(BulkImports::Clients::Graphql) do |client|
          allow(client)
            .to receive(:execute)
            .and_return(instance_double(GraphQL::Client::Response, original_hash: {
              'data' => { 'group' => { 'id' => 'gid://gitlab/Group/165' } }
            }))

          allow(client).to receive(:parse)
        end

        stub_request(:get, "http://gitlab.example/api/v4/#{source_entity_type}/#{source_entity_identifier}/export_relations/status?page=1&per_page=30&private_token=token")
          .to_return(
            status: 200
          )

        parent_group.add_owner(user)
      end

      it 'creates bulk import' do
        expect { subject.execute }.to change { BulkImport.count }.by(1)

        last_bulk_import = BulkImport.last

        expect(last_bulk_import.user).to eq(user)
        expect(last_bulk_import.source_version).to eq(source_version.to_s)
        expect(last_bulk_import.user).to eq(user)
        expect(last_bulk_import.source_enterprise).to eq(false)

        expect_snowplow_event(
          category: 'BulkImports::CreateService',
          action: 'create',
          label: 'bulk_import_group',
          extra: { source_equals_destination: false }
        )

        expect_snowplow_event(
          category: 'BulkImports::CreateService',
          action: 'create',
          label: 'import_access_level',
          user: user,
          extra: { user_role: 'Owner', import_type: 'bulk_import_group' }
        )
      end

      it 'enables importer_user_mapping' do
        subject.execute

        expect(Import::BulkImports::EphemeralData.new(BulkImport.last.id).importer_user_mapping_enabled?).to eq(true)
      end

      it 'enqueues SourceUsersAttributesWorker' do
        expect(Import::BulkImports::SourceUsersAttributesWorker).to receive(:perform_async)

        subject.execute
      end

      context 'when importer_user_mapping feature flag is disable' do
        before do
          stub_feature_flags(importer_user_mapping: false)
        end

        it 'does not enable importer_user_mapping' do
          subject.execute

          expect(Import::BulkImports::EphemeralData.new(BulkImport.last.id).importer_user_mapping_enabled?).to eq(false)
        end

        it 'does not enqueue SourceUsersAttributesWorker' do
          expect(Import::BulkImports::SourceUsersAttributesWorker).not_to receive(:perform_async)

          subject.execute
        end
      end

      context 'when bulk_import_importer_user_mapping feature flag is disable' do
        before do
          stub_feature_flags(bulk_import_importer_user_mapping: false)
        end

        it 'does not enable importer_user_mapping' do
          subject.execute

          expect(Import::BulkImports::EphemeralData.new(BulkImport.last.id).importer_user_mapping_enabled?).to eq(false)
        end
      end

      context 'on the same instance' do
        before do
          allow(Settings.gitlab).to receive(:base_url).and_return('http://gitlab.example')
        end

        it 'tracks the same instance migration' do
          expect { subject.execute }.to change { BulkImport.count }.by(1)

          expect_snowplow_event(
            category: 'BulkImports::CreateService',
            action: 'create',
            label: 'bulk_import_group',
            extra: { source_equals_destination: true }
          )
        end
      end

      it 'creates bulk import entities' do
        expect { subject.execute }.to change { BulkImports::Entity.count }.by(3)
      end

      it 'creates bulk import configuration' do
        expect { subject.execute }.to change { BulkImports::Configuration.count }.by(1)
      end

      it 'enqueues BulkImportWorker' do
        expect(BulkImportWorker).to receive(:perform_async)

        subject.execute
      end

      it 'returns success ServiceResponse' do
        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result).to be_success
      end

      it 'returns ServiceResponse with error if validation fails' do
        params[0][:source_full_path] = nil

        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
        expect(result.message).to eq("Validation failed: Source full path can't be blank, " \
                                     "Source full path must have a relative path structure with " \
                                     "no HTTP protocol characters, or leading or trailing forward slashes. " \
                                     "Path segments must not start or end with a special character, and " \
                                     "must not contain consecutive special characters")
      end

      describe '#user-role' do
        context 'when there is a parent_namespace and the user is a member' do
          let(:group2) { create(:group, path: 'destination200', source_id: parent_group.id) }
          let(:params) do
            [
              {
                source_type: 'group_entity',
                source_full_path: 'full/path/to/group1',
                destination_slug: 'destination200',
                destination_namespace: 'parent-group'
              }
            ]
          end

          it 'defines access_level from parent namespace membership' do
            parent_group.add_guest(user)
            subject.execute

            expect_snowplow_event(
              category: 'BulkImports::CreateService',
              action: 'create',
              label: 'import_access_level',
              user: user,
              extra: { user_role: 'Guest', import_type: 'bulk_import_group' }
            )
          end
        end

        it 'defines access_level as not a member' do
          parent_group.members.delete_all

          subject.execute
          expect_snowplow_event(
            category: 'BulkImports::CreateService',
            action: 'create',
            label: 'import_access_level',
            user: user,
            extra: { user_role: 'Not a member', import_type: 'bulk_import_group' }
          )
        end

        context 'when there is a destination_namespace but no parent_namespace' do
          let(:params) do
            [
              {
                source_type: 'group_entity',
                source_full_path: 'full/path/to/group1',
                destination_slug: 'destination-group-1',
                destination_namespace: 'destination1'
              }
            ]
          end

          it 'defines access_level from destination_namespace' do
            destination_group.add_developer(user)
            subject.execute

            expect_snowplow_event(
              category: 'BulkImports::CreateService',
              action: 'create',
              label: 'import_access_level',
              user: user,
              extra: { user_role: 'Developer', import_type: 'bulk_import_group' }
            )
          end
        end

        context 'when there is no destination_namespace or parent_namespace' do
          let(:params) do
            [
              {
                source_type: 'group_entity',
                source_full_path: 'full/path/to/group1',
                destination_slug: 'destinationational-mcdestiny',
                destination_namespace: 'destinational-mcdestiny'
              }
            ]
          end

          it 'defines access_level as owner' do
            subject.execute

            expect_snowplow_event(
              category: 'BulkImports::CreateService',
              action: 'create',
              label: 'import_access_level',
              user: user,
              extra: { user_role: 'Owner', import_type: 'bulk_import_group' }
            )
          end
        end
      end

      describe '#validate_setting_enabled!' do
        let(:entity_source_id) { 'gid://gitlab/Model/12345' }
        let(:graphql_client) { instance_double(BulkImports::Clients::Graphql) }
        let(:http_client) { instance_double(BulkImports::Clients::HTTP) }
        let(:http_response) { instance_double(HTTParty::Response, code: 200, success?: true) }

        before do
          allow(BulkImports::Clients::HTTP).to receive(:new).and_return(http_client)
          allow(BulkImports::Clients::Graphql).to receive(:new).and_return(graphql_client)

          allow(http_client).to receive(:instance_version).and_return(status: 200)
          allow(http_client).to receive(:instance_enterprise).and_return(false)
          allow(http_client).to receive(:validate_instance_version!).and_return(source_version)
          allow(http_client).to receive(:validate_import_scopes!).and_return(true)
        end

        context 'when the source_type is a group' do
          context 'when the source_full_path contains only integer characters' do
            let(:query_string) { BulkImports::Groups::Graphql::GetGroupQuery.new(context: nil).to_s }
            let(:graphql_response) do
              instance_double(GraphQL::Client::Response,
                original_hash: { 'data' => { 'group' => { 'id' => entity_source_id } } })
            end

            let(:params) do
              [
                {
                  source_type: 'group_entity',
                  source_full_path: '67890',
                  destination_slug: 'destination-group-1',
                  destination_namespace: 'destination1'
                }
              ]
            end

            before do
              allow(graphql_client).to receive(:parse).with(query_string)
              allow(graphql_client).to receive(:execute).and_return(graphql_response)

              allow(http_client).to receive(:get)
                .with("/groups/12345/export_relations/status")
                .and_return(http_response)

              stub_request(:get, "http://gitlab.example/api/v4/groups/12345/export_relations/status?page=1&per_page=30&private_token=token")
                  .to_return(status: 200, body: "", headers: {})
            end

            it 'makes a graphql request using the group full path and an http request with the correct id' do
              expect(graphql_client).to receive(:parse).with(query_string)
              expect(graphql_client).to receive(:execute).and_return(graphql_response)

              expect(http_client).to receive(:get).with("/groups/12345/export_relations/status")

              subject.execute
            end
          end
        end

        context 'when the source_type is a project' do
          context 'when the source_full_path contains only integer characters' do
            let(:query_string) { BulkImports::Projects::Graphql::GetProjectQuery.new(context: nil).to_s }
            let(:graphql_response) do
              instance_double(GraphQL::Client::Response,
                original_hash: { 'data' => { 'project' => { 'id' => entity_source_id } } })
            end

            let(:params) do
              [
                {
                  source_type: 'project_entity',
                  source_full_path: '67890',
                  destination_slug: 'destination-group-1',
                  destination_namespace: 'destination1'
                }
              ]
            end

            before do
              allow(graphql_client).to receive(:parse).with(query_string)
              allow(graphql_client).to receive(:execute).and_return(graphql_response)

              allow(http_client).to receive(:get)
                .with("/projects/12345/export_relations/status")
                .and_return(http_response)

              stub_request(:get, "http://gitlab.example/api/v4/projects/12345/export_relations/status?page=1&per_page=30&private_token=token")
                  .to_return(status: 200, body: "", headers: {})
            end

            it 'makes a graphql request using the group full path and an http request with the correct id' do
              expect(graphql_client).to receive(:parse).with(query_string)
              expect(graphql_client).to receive(:execute).and_return(graphql_response)

              expect(http_client).to receive(:get).with("/projects/12345/export_relations/status")

              subject.execute
            end
          end
        end
      end

      describe '#validate_destination_namespace' do
        before do
          allow(subject).to receive(:validate!).and_return(true)
        end

        context 'when the destination_namespace does not exist' do
          let(:params) do
            [
              {
                source_type: 'group_entity',
                source_full_path: 'full/path/to/source',
                destination_slug: 'destination-slug',
                destination_namespace: 'destination-namespace',
                migrate_projects: migrate_projects,
                migrate_memberships: migrate_memberships
              }
            ]
          end

          it 'returns ServiceResponse with an error message' do
            result = subject.execute

            expect(result).to be_a(ServiceResponse)
            expect(result).to be_error
            expect(result.message)
              .to eq("Import failed. Destination 'destination-namespace' is invalid, " \
                     "or you don't have permission.")
          end
        end

        context 'when the user does not have permission to create subgroups' do
          let(:params) do
            [
              {
                source_type: 'group_entity',
                source_full_path: 'full/path/to/source',
                destination_slug: 'destination-slug',
                destination_namespace: parent_group.path,
                migrate_projects: migrate_projects,
                migrate_memberships: migrate_memberships
              }
            ]
          end

          it 'returns ServiceResponse with an error message' do
            parent_group.members.delete_all

            result = subject.execute

            expect(result).to be_a(ServiceResponse)
            expect(result).to be_error
            expect(result.message)
            .to eq("Import failed. Destination '#{parent_group.path}' is invalid, " \
                   "or you don't have permission.")
          end
        end

        context 'when the user does not have permission to create projects' do
          let(:params) do
            [
              {
                source_type: 'project_entity',
                source_full_path: 'full/path/to/source',
                destination_slug: 'destination-slug',
                destination_namespace: parent_group.path,
                migrate_projects: migrate_projects,
                migrate_memberships: migrate_memberships
              }
            ]
          end

          it 'returns ServiceResponse with an error message' do
            parent_group.members.delete_all

            result = subject.execute

            expect(result).to be_a(ServiceResponse)
            expect(result).to be_error
            expect(result.message)
              .to eq("Import failed. Destination '#{parent_group.path}' is invalid, " \
                     "or you don't have permission.")
          end
        end
      end

      describe '#validate_destination_slug' do
        context 'when the destination_slug is invalid' do
          let(:params) do
            [
              {
                source_type: 'group_entity',
                source_full_path: 'full/path/to/source',
                destination_slug: 'destin-*-ation-slug',
                destination_namespace: parent_group.path,
                migrate_projects: migrate_projects,
                migrate_memberships: migrate_memberships
              }
            ]
          end

          it 'returns ServiceResponse with an error message' do
            result = subject.execute

            expect(result).to be_a(ServiceResponse)
            expect(result).to be_error
            expect(result.message)
              .to eq(
                "Import failed. Destination URL " \
                "can only include non-accented letters, digits, '_', '-' and '.'. " \
                "It must not start with '-', '_', or '.', nor end with '-', '_', '.', '.git', or '.atom'."
              )
          end
        end
      end

      describe '#validate_destination_full_path' do
        before do
          allow(subject).to receive(:validate!).and_return(true)
        end

        context 'when the source_type is a group' do
          context 'when the provided destination_slug already exists in the destination_namespace' do
            let_it_be(:existing_subgroup) { create(:group, path: 'existing-subgroup', parent_id: parent_group.id) }
            let_it_be(:existing_subgroup_2) { create(:group, path: 'existing-subgroup_2', parent_id: parent_group.id) }
            let(:params) do
              [
                {
                  source_type: 'group_entity',
                  source_full_path: 'full/path/to/source',
                  destination_slug: existing_subgroup.path,
                  destination_namespace: parent_group.path,
                  migrate_projects: migrate_projects,
                  migrate_memberships: migrate_memberships
                }
              ]
            end

            it 'returns ServiceResponse with an error message' do
              result = subject.execute

              expect(result).to be_a(ServiceResponse)
              expect(result).to be_error
              expect(result.message)
                .to eq(
                  "Import failed. 'parent-group/existing-subgroup' already exists. " \
                  "Change the destination and try again."
                )
            end
          end

          context 'when the destination_slug conflicts with an existing top-level namespace' do
            let_it_be(:existing_top_level_group) { create(:group, path: 'top-level-group') }
            let(:params) do
              [
                {
                  source_type: 'group_entity',
                  source_full_path: 'full/path/to/source',
                  destination_slug: existing_top_level_group.path,
                  destination_namespace: '',
                  migrate_projects: migrate_projects,
                  migrate_memberships: migrate_memberships
                }
              ]
            end

            it 'returns ServiceResponse with an error message' do
              result = subject.execute

              expect(result).to be_a(ServiceResponse)
              expect(result).to be_error
              expect(result.message)
                .to eq(
                  "Import failed. 'top-level-group' already exists. " \
                  "Change the destination and try again."
                )
            end
          end

          context 'when the destination_slug does not conflict with an existing top-level namespace' do
            let(:params) do
              [
                {
                  source_type: 'group_entity',
                  source_full_path: 'full/path/to/source',
                  destination_slug: 'new-group',
                  destination_namespace: parent_group.path,
                  migrate_projects: migrate_projects,
                  migrate_memberships: migrate_memberships
                }
              ]
            end

            it 'returns success ServiceResponse' do
              result = subject.execute

              expect(result).to be_a(ServiceResponse)
              expect(result).to be_success
            end
          end
        end

        context 'when the source_type is a project' do
          context 'when the provided destination_slug already exists in the destination_namespace' do
            let_it_be(:existing_group) { create(:group, path: 'existing-group') }
            let_it_be(:existing_project) { create(:project, path: 'existing-project', parent_id: existing_group.id) }
            let(:params) do
              [
                {
                  source_type: 'project_entity',
                  source_full_path: 'full/path/to/source',
                  destination_slug: existing_project.path,
                  destination_namespace: existing_group.path,
                  migrate_projects: migrate_projects,
                  migrate_memberships: migrate_memberships
                }
              ]
            end

            it 'returns ServiceResponse with an error message' do
              existing_group.add_owner(user)

              result = subject.execute

              expect(result).to be_a(ServiceResponse)
              expect(result).to be_error
              expect(result.message)
                .to eq(
                  "Import failed. 'existing-group/existing-project' already exists. " \
                  "Change the destination and try again."
                )
            end
          end

          context 'when the destination_slug does not conflict with an existing project' do
            let_it_be(:existing_group) { create(:group, path: 'existing-group') }
            let(:params) do
              [
                {
                  source_type: 'project_entity',
                  source_full_path: 'full/path/to/source',
                  destination_slug: 'new-project',
                  destination_namespace: 'existing-group',
                  migrate_projects: migrate_projects,
                  migrate_memberships: migrate_memberships
                }
              ]
            end

            it 'returns success ServiceResponse' do
              existing_group.add_owner(user)

              result = subject.execute

              expect(result).to be_a(ServiceResponse)
              expect(result).to be_success
            end
          end
        end
      end
    end
  end
end
