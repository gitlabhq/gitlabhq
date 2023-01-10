# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::CreateService, feature_category: :importers do
  let(:user) { create(:user) }
  let(:credentials) { { url: 'http://gitlab.example', access_token: 'token' } }
  let(:destination_group) { create(:group, path: 'destination1') }
  let_it_be(:parent_group) { create(:group, path: 'parent-group') }
  let(:params) do
    [
      {
        source_type: 'group_entity',
        source_full_path: 'full/path/to/group1',
        destination_slug: 'destination group 1',
        destination_namespace: 'parent-group'
      },
      {
        source_type: 'group_entity',
        source_full_path: 'full/path/to/group2',
        destination_slug: 'destination group 2',
        destination_namespace: 'parent-group'
      },
      {
        source_type: 'project_entity',
        source_full_path: 'full/path/to/project1',
        destination_slug: 'destination project 1',
        destination_namespace: 'parent-group'
      }
    ]
  end

  subject { described_class.new(user, params, credentials) }

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

      context 'when required scopes are not present' do
        it 'returns ServiceResponse with error if token does not have api scope' do
          stub_request(:get, 'http://gitlab.example/api/v4/version?private_token=token').to_return(status: 404)
          stub_request(:get, 'http://gitlab.example/api/v4/metadata?private_token=token')
            .to_return(
              status: 200,
              body: source_version.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
            allow(client).to receive(:validate_instance_version!).and_raise(BulkImports::Error.scope_validation_failure)
          end

          result = subject.execute

          expect(result).to be_a(ServiceResponse)
          expect(result).to be_error
          expect(result.message)
            .to eq(
              "Import aborted as the provided personal access token does not have the required 'api' scope or is " \
              "no longer valid."
            )
        end
      end

      context 'when token validation succeeds' do
        it 'creates bulk import' do
          stub_request(:get, 'http://gitlab.example/api/v4/version?private_token=token').to_return(status: 404)
          stub_request(:get, 'http://gitlab.example/api/v4/metadata?private_token=token')
            .to_return(status: 200, body: source_version.to_json, headers: { 'Content-Type' => 'application/json' })
          stub_request(:get, 'http://gitlab.example/api/v4/personal_access_tokens/self?private_token=token')
            .to_return(
              status: 200,
              body: { 'scopes' => ['api'] }.to_json,
              headers: { 'Content-Type' => 'application/json' }
            )

          parent_group.add_owner(user)
          expect { subject.execute }.to change { BulkImport.count }.by(1)

          last_bulk_import = BulkImport.last
          expect(last_bulk_import.user).to eq(user)
          expect(last_bulk_import.source_version).to eq(source_version[:version])
          expect(last_bulk_import.user).to eq(user)
          expect(last_bulk_import.source_enterprise).to eq(false)

          expect_snowplow_event(
            category: 'BulkImports::CreateService',
            action: 'create',
            label: 'bulk_import_group'
          )

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

    context 'when gitlab version is lower than 15.5' do
      let(:source_version) do
        Gitlab::VersionInfo.new(::BulkImport::MIN_MAJOR_VERSION,
                                ::BulkImport::MIN_MINOR_VERSION_FOR_PROJECT)
      end

      before do
        allow_next_instance_of(BulkImports::Clients::HTTP) do |instance|
          allow(instance).to receive(:instance_version).and_return(source_version)
          allow(instance).to receive(:instance_enterprise).and_return(false)
        end
      end

      it 'creates bulk import' do
        parent_group.add_owner(user)
        expect { subject.execute }.to change { BulkImport.count }.by(1)

        last_bulk_import = BulkImport.last

        expect(last_bulk_import.user).to eq(user)
        expect(last_bulk_import.source_version).to eq(source_version.to_s)
        expect(last_bulk_import.user).to eq(user)
        expect(last_bulk_import.source_enterprise).to eq(false)

        expect_snowplow_event(
          category: 'BulkImports::CreateService',
          action: 'create',
          label: 'bulk_import_group'
        )

        expect_snowplow_event(
          category: 'BulkImports::CreateService',
          action: 'create',
          label: 'import_access_level',
          user: user,
          extra: { user_role: 'Owner', import_type: 'bulk_import_group' }
        )
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
        expect(result.message).to eq("Validation failed: Source full path can't be blank")
      end

      describe '#user-role' do
        context 'when there is a parent_namespace and the user is a member' do
          let(:group2) { create(:group, path: 'destination200', source_id: parent_group.id ) }
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
          subject.execute
          expect_snowplow_event(
            category: 'BulkImports::CreateService',
            action: 'create',
            label: 'import_access_level',
            user: user,
            extra: { user_role: 'Not a member', import_type: 'bulk_import_group' }
          )
        end
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
              destination_slug: 'destinationational mcdestiny',
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
  end
end
