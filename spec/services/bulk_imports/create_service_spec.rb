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
        destination_namespace: 'full/path/to/destination1'
      },
      {
        source_type: 'group_entity',
        source_full_path: 'full/path/to/group2',
        destination_slug: 'destination group 2',
        destination_namespace: 'full/path/to/destination2'
      },
      {
        source_type: 'project_entity',
        source_full_path: 'full/path/to/project1',
        destination_slug: 'destination project 1',
        destination_namespace: 'full/path/to/destination1'
      }
    ]
  end

  subject { described_class.new(user, params, credentials) }

  describe '#execute' do
    let_it_be(:source_version) do
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

    context 'when the token is invalid' do
      before do
        allow_next_instance_of(BulkImports::Clients::HTTP) do |client|
          allow(client).to receive(:instance_version).and_raise(BulkImports::NetworkError, "401 Unauthorized")
        end
      end

      it 'rescues the error and raises a ServiceResponse::Error' do
        result = subject.execute

        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
        expect(result.message).to eq("401 Unauthorized")
      end
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

      context 'when there is a parent_namespace and the user is not a member' do
        let(:params) do
          [
            {
              source_type: 'group_entity',
              source_full_path: 'full/path/to/group1',
              destination_slug: 'destination-group-1',
              destination_namespace: 'parent-group'
            }
          ]
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
