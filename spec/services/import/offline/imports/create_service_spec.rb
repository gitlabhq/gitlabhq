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
  end
end
