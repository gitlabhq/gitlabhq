# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Offline::Imports::CreateService, :aggregate_failures, feature_category: :importers do
  describe '#execute' do
    let_it_be(:organization) { create(:common_organization) }
    let_it_be(:user) { create(:user) }
    let_it_be(:destination_group) { create(:group, owners: user, organization: organization) }
    let(:destination_namespace) { destination_group.full_path }

    let(:object_storage_configuration) do
      {
        bucket: 'my-bucket',
        provider: 'aws',
        export_prefix: '2026-02-23_11-52-43_export_iW11t5cQ',
        object_storage_credentials: {
          aws_access_key_id: 'AwsUserAccessKey',
          aws_secret_access_key: 'aws/secret+access/key',
          region: 'us-east-1',
          path_style: false
        }.stringify_keys
      }
    end

    let(:params) do
      {
        entities: [
          {
            source_type: 'group_entity',
            source_full_path: 'top_level_group',
            destination_namespace: destination_namespace,
            destination_slug: 'dest-grp-0123'
          }
        ]
      }
    end

    subject(:service) do
      described_class.new(
        object_storage_configuration,
        params,
        current_user: user,
        fallback_organization: organization
      )
    end

    it 'returns a success result' do
      response = service.execute
      expect(response).to be_success
      expect(response.payload).to be_a(BulkImport)
    end

    it 'triggers the ScheduleImportWorker' do
      expect(Import::Offline::Imports::ScheduleImportWorker).to receive(:perform_async).with(
        an_instance_of(Integer),
        params[:entities].map(&:deep_stringify_keys)
      )

      service.execute
    end

    it 'creates an empty bulk import for import scaffolding' do
      expect { service.execute }
        .to change { BulkImport.count }.by(1)

      expect(BulkImport.last).to have_attributes(
        user: user,
        source_version: nil,
        source_enterprise: false,
        organization: organization
      )
    end

    it 'creates the offline transfer configuration' do
      expect { service.execute }
        .to change { Import::Offline::Configuration.count }.by(1)

      expect(Import::Offline::Configuration.last).to have_attributes(
        object_storage_configuration
      )
    end

    it 'validates the destination namespace' do
      expect_next_instance_of(::Import::Framework::DestinationValidator) do |validator|
        expect(validator).to receive(:validate!)
      end

      service.execute
    end

    context 'when no destination namespace is provided' do
      let_it_be(:organization) { create(:organization) }
      let(:destination_namespace) { '' }

      it 'uses the fallback organization' do
        expect { service.execute }
          .to change { BulkImport.count }.by(1)

        bulk_import = BulkImport.last

        expect(bulk_import.organization_id).to eq(organization.id)
      end
    end

    context 'when user does not have permission on specified import destination' do
      let(:destination_namespace) { 'some/unknown/group' }

      it 'returns an error object' do
        response = service.execute

        expect(response).to be_error
        expect(response.message).to eq(s_('OfflineTransfer|One or more destination paths is invalid.'))
      end
    end

    context 'when offline_transfer_imports is disabled' do
      before do
        stub_feature_flags(offline_transfer_imports: false)
      end

      it 'returns an error' do
        response = service.execute

        expect(response).to be_error
        expect(response.message).to eq('offline_transfer_imports feature flag must be enabled.')
      end
    end

    describe 'cross-organization destination validation' do
      let_it_be_with_reload(:request_organization) { create(:organization, path: 'request-org') }
      let_it_be_with_reload(:other_organization) { create(:organization, path: 'other-org') }
      let_it_be(:request_org_group) do
        create(:group, organization: request_organization, path: 'request-org-group', owners: user)
      end

      let_it_be(:other_org_group) do
        create(:group, organization: other_organization, path: 'other-org-group', owners: user)
      end

      let(:destination_namespace) { other_org_group.full_path }

      subject(:service) do
        described_class.new(
          object_storage_configuration,
          params,
          current_user: user,
          fallback_organization: request_organization
        )
      end

      shared_examples 'rejects the cross-organization import' do
        it 'rejects the import and does not create a BulkImport' do
          result = nil
          expect { result = service.execute }.not_to change { BulkImport.count }
          expect(result).to be_error
          expect(result.message).to include(other_org_group.full_path)
          expect(result.message).to match(/belongs to a different organization than the current one/)
        end
      end

      context 'when neither organization is isolated' do
        it 'allows the cross-organization import (preserves today’s behavior)' do
          expect(service.execute).to be_success
        end
      end

      context 'when the destination resolves to the request organization' do
        let(:destination_namespace) { request_org_group.full_path }

        before do
          request_organization.mark_as_isolated!
        end

        it 'allows the import to proceed' do
          expect(service.execute).to be_success
        end
      end

      context 'when the request organization is isolated' do
        before do
          request_organization.mark_as_isolated!
        end

        it_behaves_like 'rejects the cross-organization import'
      end

      context 'when the destination organization is isolated' do
        before do
          other_organization.mark_as_isolated!
        end

        it_behaves_like 'rejects the cross-organization import'
      end

      context 'when the destination namespace casing differs from the canonical path' do
        let(:destination_namespace) { other_org_group.full_path.upcase }

        before do
          request_organization.mark_as_isolated!
        end

        it 'still resolves the destination and rejects the import' do
          result = nil
          expect { result = service.execute }.not_to change { BulkImport.count }
          expect(result).to be_error
          expect(result.message).to match(/belongs to a different organization than the current one/)
        end
      end

      context 'when one of multiple entities targets a cross-organization destination' do
        let(:params) do
          {
            entities: [
              {
                source_type: 'group_entity',
                source_full_path: 'grp1',
                destination_namespace: request_org_group.full_path,
                destination_slug: 'slug-1'
              },
              {
                source_type: 'group_entity',
                source_full_path: 'grp2',
                destination_namespace: other_org_group.full_path,
                destination_slug: 'slug-2'
              }
            ]
          }
        end

        before do
          request_organization.mark_as_isolated!
        end

        it 'rejects the import and does not create a BulkImport even when the first entity is in-organization' do
          result = nil
          expect { result = service.execute }.not_to change { BulkImport.count }
          expect(result).to be_error
          expect(result.message).to include(other_org_group.full_path)
          expect(result.message).to match(/belongs to a different organization than the current one/)
        end
      end
    end
  end
end
