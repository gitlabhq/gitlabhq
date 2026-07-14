# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::ActivateWorker, feature_category: :organization do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:organization) do
    create(:organization, :confirmed, owners: user)
  end

  let(:event) do
    Organizations::ConfirmedEvent.new(data: { organization_id: organization.id })
  end

  subject(:use_event) { consume_event(subscriber: described_class, event: event) }

  it_behaves_like 'subscribes to event'

  it 'calls Organizations::ActivateService with the confirmed_by_user and organization_id' do
    expect_next_instance_of(
      Organizations::ActivateService,
      user,
      { organization_id: organization.id }
    ) do |service|
      expect(service).to receive(:execute).and_return(ServiceResponse.success)
    end

    use_event
  end

  context 'when the organization no longer exists' do
    let(:event) do
      Organizations::ConfirmedEvent.new(data: { organization_id: non_existing_record_id })
    end

    it 'does not call the activate service' do
      expect(Organizations::ActivateService).not_to receive(:new)

      use_event
    end
  end

  context 'when the organization has no confirmed_by_user_id in state_metadata' do
    before do
      organization.state_metadata.delete('confirmed_by_user_id')
      organization.organization_detail.save!
    end

    it 'does not call the activate service' do
      expect(Organizations::ActivateService).not_to receive(:new)

      use_event
    end
  end

  context 'when the confirming user no longer exists' do
    before do
      organization.state_metadata['confirmed_by_user_id'] = non_existing_record_id
      organization.organization_detail.save!
    end

    it 'does not call the activate service' do
      expect(Organizations::ActivateService).not_to receive(:new)

      use_event
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
