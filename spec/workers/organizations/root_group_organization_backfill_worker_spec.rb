# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::RootGroupOrganizationBackfillWorker, feature_category: :organization do
  # rubocop:disable Gitlab/RSpec/AvoidCreateDefaultOrganization -- Needed to test backfill from/to default org
  let_it_be(:default_organization) { create(:organization, :default) }
  # rubocop:enable Gitlab/RSpec/AvoidCreateDefaultOrganization

  describe '#handle_event' do
    context 'when operation is enabled globally' do
      let(:event) do
        Gitlab::FeatureFlags::FeatureFlagModifiedEvent.new(data: {
          feature_key: 'root_group_organization_backfill',
          operation: Feature::OPERATION_ENABLED_GLOBALLY,
          actor: nil,
          state: 'enabled'
        })
      end

      it 'does nothing (global operations not supported)' do
        expect(Organizations::Transfer::TopLevelGroupService).not_to receive(:new)

        consume_event(subscriber: described_class, event: event)
      end
    end

    context 'when operation is disabled globally' do
      let(:event) do
        Gitlab::FeatureFlags::FeatureFlagModifiedEvent.new(data: {
          feature_key: 'root_group_organization_backfill',
          operation: Feature::OPERATION_DISABLED_GLOBALLY,
          actor: nil,
          state: 'disabled'
        })
      end

      it 'does nothing (global operations not supported)' do
        expect(Organizations::Transfer::TopLevelGroupService).not_to receive(:new)

        consume_event(subscriber: described_class, event: event)
      end
    end

    context 'when operation is enabled for actor' do
      let_it_be(:group) { create(:group, organization: default_organization) }

      let(:event) do
        Gitlab::FeatureFlags::FeatureFlagModifiedEvent.new(data: {
          feature_key: 'root_group_organization_backfill',
          operation: Feature::OPERATION_ENABLED_ACTOR,
          actor: "Group:#{group.id}",
          state: 'conditional'
        })
      end

      before do
        stub_feature_flags(root_group_organization_backfill: group)
      end

      it 'creates organization and transfers the specific group' do
        expect { consume_event(subscriber: described_class, event: event) }
          .to change { Organizations::Organization.count }.by(1)

        group.reload
        expect(group.organization).not_to eq(default_organization)
        expect(group.organization.path).to eq(group.path)
      end

      context 'when group is not in default organization' do
        let_it_be(:other_org) { create(:organization) }
        let_it_be(:group) { create(:group, organization: other_org) }

        it 'logs the skip without transferring the group' do
          expect(Sidekiq.logger).to receive(:info).with(
            hash_including(
              'message' => 'Group not in default organization, skipping backfill',
              'group_id' => group.id
            )
          )

          expect { consume_event(subscriber: described_class, event: event) }
            .not_to change { Organizations::Organization.count }

          group.reload
          expect(group.organization).to eq(other_org)
        end
      end

      context 'when group is a subgroup' do
        let_it_be(:parent_group) { create(:group, organization: default_organization) }
        let_it_be(:subgroup) { create(:group, parent: parent_group, organization: default_organization) }

        let(:event) do
          Gitlab::FeatureFlags::FeatureFlagModifiedEvent.new(data: {
            feature_key: 'root_group_organization_backfill',
            operation: Feature::OPERATION_ENABLED_ACTOR,
            actor: "Group:#{subgroup.id}",
            state: 'conditional'
          })
        end

        it 'does not transfer the subgroup' do
          expect { consume_event(subscriber: described_class, event: event) }
            .not_to change { Organizations::Organization.count }

          subgroup.reload
          expect(subgroup.organization).to eq(default_organization)
        end
      end

      context 'when group path fails organization validation' do
        let_it_be(:group) { create(:group, path: 'badges', organization: default_organization) }

        let(:event) do
          Gitlab::FeatureFlags::FeatureFlagModifiedEvent.new(data: {
            feature_key: 'root_group_organization_backfill',
            operation: Feature::OPERATION_ENABLED_ACTOR,
            actor: "Group:#{group.id}",
            state: 'conditional'
          })
        end

        before do
          stub_feature_flags(root_group_organization_backfill: group)
        end

        it 'uses fallback path with group id' do
          expect { consume_event(subscriber: described_class, event: event) }
            .to change { Organizations::Organization.count }.by(1)

          group.reload
          expect(group.organization.path).to eq("organization-#{group.id}")
        end
      end
    end

    context 'when operation is disabled for actor' do
      let_it_be(:unconfirmed_org) { create(:organization, state: :unconfirmed, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
      let_it_be(:group) { create(:group, organization: unconfirmed_org) }

      let(:event) do
        Gitlab::FeatureFlags::FeatureFlagModifiedEvent.new(data: {
          feature_key: 'root_group_organization_backfill',
          operation: Feature::OPERATION_DISABLED_ACTOR,
          actor: "Group:#{group.id}",
          state: 'conditional'
        })
      end

      before do
        stub_feature_flags(root_group_organization_backfill: false)
      end

      it 'transfers group back to default organization' do
        consume_event(subscriber: described_class, event: event)

        group.reload
        expect(group.organization).to eq(default_organization)
      end

      it 'deletes unconfirmed organization if empty' do
        consume_event(subscriber: described_class, event: event)

        expect { unconfirmed_org.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end

      context 'when organization has multiple groups' do
        let_it_be(:group2) { create(:group, organization: unconfirmed_org) }

        it 'does not delete the organization' do
          consume_event(subscriber: described_class, event: event)

          expect(unconfirmed_org.reload).to be_present
        end
      end
    end

    context 'when actor is not a Group' do
      let(:event) do
        Gitlab::FeatureFlags::FeatureFlagModifiedEvent.new(data: {
          feature_key: 'root_group_organization_backfill',
          operation: Feature::OPERATION_ENABLED_ACTOR,
          actor: 'User:123',
          state: 'conditional'
        })
      end

      it 'does nothing' do
        expect(Organizations::CreateService).not_to receive(:new)
        expect(Organizations::Transfer::TopLevelGroupService).not_to receive(:new)

        consume_event(subscriber: described_class, event: event)
      end
    end

    context 'when errors occur' do
      let_it_be(:group) { create(:group, organization: default_organization) }

      let(:event) do
        Gitlab::FeatureFlags::FeatureFlagModifiedEvent.new(data: {
          feature_key: 'root_group_organization_backfill',
          operation: Feature::OPERATION_ENABLED_ACTOR,
          actor: "Group:#{group.id}",
          state: 'conditional'
        })
      end

      before do
        stub_feature_flags(root_group_organization_backfill: group)
      end

      it 'raises the exception' do
        allow_next_instance_of(Organizations::Organization) do |org|
          allow(org).to receive(:save).and_raise(StandardError.new('test error'))
        end

        expect { consume_event(subscriber: described_class, event: event) }.to raise_error(StandardError, 'test error')
      end

      context 'when the organization cannot be created' do
        before do
          allow_next_instance_of(Organizations::CreateFromGroupService) do |service|
            allow(service).to receive(:execute).and_return(
              ServiceResponse.error(message: 'Name is invalid', reason: :organization_not_created)
            )
          end
        end

        it 'logs the failure and raises' do
          expect(Sidekiq.logger).to receive(:error).with(
            hash_including(
              'message' => 'Failed to create organization',
              'group_id' => group.id,
              'error_message' => 'Name is invalid'
            )
          )

          expect { consume_event(subscriber: described_class, event: event) }
            .to raise_error("Failed to create organization for group #{group.id}: Name is invalid")
        end
      end

      context 'when the group cannot be transferred' do
        let_it_be(:organization) { create(:organization, state: :unconfirmed) }

        before do
          allow_next_instance_of(Organizations::CreateFromGroupService) do |service|
            allow(service).to receive(:execute).and_return(
              ServiceResponse.error(
                message: 'transfer failed',
                reason: :group_not_transferred,
                payload: { organization: organization }
              )
            )
          end
        end

        it 'logs the orphaned organization and raises' do
          expect(Sidekiq.logger).to receive(:error).with(
            hash_including(
              'message' => 'Failed to transfer group',
              'group_id' => group.id,
              Labkit::Fields::GL_ORGANIZATION_ID => organization.id,
              'error_message' => 'transfer failed'
            )
          )

          expect { consume_event(subscriber: described_class, event: event) }
            .to raise_error(
              "Failed to transfer group #{group.id} to organization #{organization.id}: transfer failed"
            )
        end
      end

      context 'when the service reports an unrecognized reason' do
        before do
          allow_next_instance_of(Organizations::CreateFromGroupService) do |service|
            allow(service).to receive(:execute).and_return(
              ServiceResponse.error(message: 'something else', reason: :something_else)
            )
          end
        end

        it 'logs the failure and raises rather than silently skipping' do
          expect(Sidekiq.logger).to receive(:error).with(
            hash_including(
              'message' => 'Failed to backfill organization',
              'group_id' => group.id,
              'error_reason' => :something_else,
              'error_message' => 'something else'
            )
          )

          expect { consume_event(subscriber: described_class, event: event) }
            .to raise_error("Failed to backfill organization for group #{group.id} (something_else): something else")
        end
      end
    end
  end

  describe 'worker attributes' do
    it 'is idempotent' do
      expect(described_class).to be_idempotent
    end

    it 'has the correct feature category' do
      expect(described_class.get_feature_category).to eq(:organization)
    end

    it 'has low urgency' do
      expect(described_class.get_urgency).to eq(:low)
    end
  end
end
