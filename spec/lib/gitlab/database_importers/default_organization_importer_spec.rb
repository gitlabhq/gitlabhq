# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DatabaseImporters::DefaultOrganizationImporter, feature_category: :organization do
  describe '#create_default_organization' do
    let(:default_id) { Organizations::Organization::DEFAULT_ORGANIZATION_ID }

    subject { described_class.create_default_organization }

    context 'when default organization does not exists' do
      it 'creates a default organization' do
        expect(Organizations::Organization.find_by(id: default_id)).to be_nil

        subject

        default_org = Organizations::Organization.find(default_id)

        expect(default_org.name).to eq('Default')
        expect(default_org.path).to eq('default')
        expect(default_org).to be_public
        expect(default_org).to be_active
      end

      it 'creates the default organization without confirmed_by_user_id' do
        subject

        default_org = Organizations::Organization.find(default_id)

        expect(default_org.organization_detail.confirmed_by_user_id).to be_nil
        expect(default_org.organization_detail.confirmed_at).to be_nil
      end

      context 'when the organization env vars are set' do
        before do
          stub_env('GITLAB_ROOT_ORG_NAME' => 'Acme')
          stub_env('GITLAB_ROOT_ORG_PATH' => 'acme')
        end

        it 'uses them for the name and path while remaining the default organization', :aggregate_failures do
          subject

          default_org = Organizations::Organization.find(default_id)

          expect(default_org.name).to eq('Acme')
          expect(default_org.path).to eq('acme')
          expect(default_org).to be_default
        end
      end
    end

    context 'when default organization exists' do
      let!(:default_org) { create(:organization, :default) } # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- required for testing idempotent behavior

      it 'does not create another organization' do
        expect { subject }.not_to change { Organizations::Organization.count }
      end
    end

    # https://gitlab.com/gitlab-org/gitlab/-/work_items/499203
    context 'when cells are enabled' do
      let(:claim_service) { Gitlab::TopologyServiceClient::ClaimService.instance }

      before do
        stub_config_cell(enabled: true, id: cell_id)
        allow(Current).to receive(:cells_claims_leases?).and_return(true)
      end

      context 'on the legacy cell' do
        let(:cell_id) { 1 }

        before do
          allow(claim_service).to receive(:commit_update)
          allow(claim_service).to receive(:begin_update).and_return(
            Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateResponse.new(
              lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: SecureRandom.uuid)))
        end

        it 'creates the default organization and claims it', :aggregate_failures do
          expect { subject }
            .to change { Organizations::Organization.where(id: default_id).count }.from(0).to(1)

          expect(claim_service).to have_received(:begin_update)
        end
      end

      context 'on another cell' do
        let(:cell_id) { 2 }

        it 'does not create the default organization or contact the Topology Service', :aggregate_failures do
          expect(Gitlab::TopologyServiceClient::ClaimService).not_to receive(:instance)
          expect(Gitlab::AppLogger).to receive(:info).with(
            hash_including(
              message: 'Skipping default organization creation, it belongs to the legacy cell',
              cell_id: cell_id
            )
          )

          expect { subject }.not_to change { Organizations::Organization.count }
        end
      end
    end
  end
end
