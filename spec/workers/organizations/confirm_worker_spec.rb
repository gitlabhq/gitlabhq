# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::ConfirmWorker, feature_category: :organization do
  describe '#handle_event' do
    let_it_be_with_reload(:organization) { create(:organization, :unconfirmed) }
    let_it_be(:admin_bot) { ::Users::Internal.in_organization(organization.id).admin_bot }

    let(:event) do
      Gitlab::FeatureFlags::FeatureFlagModifiedEvent.new(data: {
        feature_key: 'root_group_organization_confirm',
        operation: operation,
        actor: actor,
        state: 'conditional'
      })
    end

    let(:operation) { Feature::OPERATION_ENABLED_ACTOR }
    let(:actor) { organization.flipper_id }

    before do
      stub_feature_flags(root_group_organization_confirm: organization)
    end

    context 'when operation is enabled for actor' do
      it_behaves_like 'subscribes to event'

      it 'calls Organizations::ConfirmService with the admin bot user' do
        expect_next_instance_of(
          Organizations::ConfirmService,
          admin_bot,
          { organization_id: organization.id }
        ) do |service|
          expect(service).to receive(:execute).and_return(ServiceResponse.success)
        end

        consume_event(subscriber: described_class, event: event)
      end

      it 'confirms the organization' do
        expect { consume_event(subscriber: described_class, event: event) }
          .to change { organization.reload.state }.from('unconfirmed').to('confirmed')
      end
    end

    context 'when operation is not enabled_actor' do
      let(:operation) { Feature::OPERATION_ENABLED_GLOBALLY }

      it 'does not call Organizations::ConfirmService' do
        expect(Organizations::ConfirmService).not_to receive(:new)

        consume_event(subscriber: described_class, event: event)
      end
    end

    context 'when operation is disabled_actor' do
      let(:operation) { Feature::OPERATION_DISABLED_ACTOR }

      it 'does not call Organizations::ConfirmService' do
        expect(Organizations::ConfirmService).not_to receive(:new)

        consume_event(subscriber: described_class, event: event)
      end
    end

    context 'when actor is not an Organization' do
      let(:actor) { "Group:#{create(:group).id}" }

      it 'does not call Organizations::ConfirmService' do
        expect(Organizations::ConfirmService).not_to receive(:new)

        consume_event(subscriber: described_class, event: event)
      end
    end

    context 'when actor is nil' do
      let(:actor) { nil }

      it 'does not call Organizations::ConfirmService' do
        expect(Organizations::ConfirmService).not_to receive(:new)

        consume_event(subscriber: described_class, event: event)
      end
    end

    context 'when organization does not exist' do
      let(:actor) { Organizations::Organization.actor_from_id(non_existing_record_id).flipper_id }

      it 'does not call Organizations::ConfirmService' do
        expect(Organizations::ConfirmService).not_to receive(:new)

        consume_event(subscriber: described_class, event: event)
      end
    end

    context 'when feature flag is not enabled for the organization' do
      before do
        stub_feature_flags(root_group_organization_confirm: false)
      end

      it 'does not call Organizations::ConfirmService' do
        expect(Organizations::ConfirmService).not_to receive(:new)

        consume_event(subscriber: described_class, event: event)
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
