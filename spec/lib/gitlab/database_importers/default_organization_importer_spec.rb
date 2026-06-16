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
    end

    context 'when default organization exists' do
      let!(:default_org) { create(:organization, :default) } # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- required for testing idempotent behavior

      it 'does not create another organization' do
        expect { subject }.not_to change { Organizations::Organization.count }
      end
    end

    # https://gitlab.com/gitlab-org/gitlab/-/work_items/499203
    #
    # In a multi-cell cluster the Organization `path` is a cluster-wide claim
    # (Organizations::Organization includes Cells::Claimable, claiming `path`).
    # The Default organization (path: "default") can only be claimed by a single
    # cell. On every other cell, when the fixture tries to create it, the
    # Topology Service rejects the claim with gRPC ALREADY_EXISTS during lease
    # creation, which surfaces as Cells::TransactionRecord::AlreadyClaimedError.
    # The importer skips creation in that case; any other lease failure raises
    # the generic Cells::TransactionRecord::Error and aborts seeding.
    context 'when running in a multi-cell cluster' do
      let(:claim_service) { Gitlab::TopologyServiceClient::ClaimService.instance }

      before do
        stub_config_cell(enabled: true)
        allow(Current).to receive(:cells_claims_leases?).and_return(true)
        allow(GRPC::Core::TimeConsts).to receive(:from_relative_time).and_return(10.seconds.from_now.to_i)
      end

      context 'when the default organization path is already claimed by another cell' do
        before do
          allow(claim_service).to receive(:begin_update)
            .and_raise(GRPC::AlreadyExists.new('organization path "default" is already claimed'))
        end

        it 'does not abort, leaves no local default organization, and leaks no lease' do
          expect { subject }.not_to raise_error

          expect(Organizations::Organization.find_by(id: default_id)).to be_nil
          expect(Cells::OutstandingLease.count).to eq(0)
        end
      end

      context 'when the lease fails for any other reason' do
        before do
          # Anything that is not an ALREADY_EXISTS claim collision (timeouts,
          # infrastructure errors) must not be swallowed: provisioning on the
          # owning cell should fail loudly rather than silently skip seeding.
          allow(claim_service).to receive(:begin_update)
            .and_raise(GRPC::Internal.new('topology service unavailable'))
        end

        it 'propagates the error without swallowing it as a claim collision' do
          expect { subject }.to raise_error(Cells::TransactionRecord::Error) do |error|
            expect(error).not_to be_a(Cells::TransactionRecord::AlreadyClaimedError)
          end

          expect(Organizations::Organization.find_by(id: default_id)).to be_nil
        end
      end

      # Control: with the same multi-cell harness (cell enabled + leases on), the
      # cell that successfully claims the path still creates the organization.
      # This isolates the skip behaviour above to the ALREADY_EXISTS collision
      # rather than to running with claims enabled at all.
      context 'when this cell successfully claims the default organization path' do
        before do
          allow(claim_service).to receive(:begin_update).and_return(
            Gitlab::Cells::TopologyService::Claims::V1::BeginUpdateResponse.new(
              lease_uuid: Gitlab::Cells::TopologyService::Types::V1::UUID.new(value: SecureRandom.uuid)))
          allow(claim_service).to receive(:commit_update)
        end

        it 'creates the default organization' do
          expect { subject }
            .to change { Organizations::Organization.where(id: default_id).count }.from(0).to(1)
        end
      end
    end
  end
end
