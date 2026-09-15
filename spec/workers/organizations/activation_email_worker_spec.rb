# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::ActivationEmailWorker, feature_category: :organization do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:organization) do
    create(:organization, :confirmed, owners: user)
  end

  let(:event) { Organizations::ActivatedEvent.build(organization: organization) }

  subject(:use_event) { consume_event(subscriber: described_class, event: event) }

  it_behaves_like 'subscribes to event'

  it 'sends the activation email to the confirming user' do
    expect(Notify).to receive(:organization_activated_email)
      .with(organization.id, user.id)
      .and_return(instance_double(ActionMailer::MessageDelivery, deliver_later: nil))

    use_event
  end

  it 'enqueues the email for delivery' do
    expect { use_event }.to have_enqueued_mail(Notify, :organization_activated_email)
  end

  context 'when the organization no longer exists' do
    let(:event) do
      Organizations::ActivatedEvent.build(organization: build_stubbed(:organization, id: non_existing_record_id))
    end

    it 'does not send an email' do
      expect(Notify).not_to receive(:organization_activated_email)

      use_event
    end
  end

  context 'when the organization has no confirmed_by_user_id in state_metadata' do
    before do
      organization.state_metadata.delete('confirmed_by_user_id')
      organization.organization_detail.save!
    end

    it 'does not send an email' do
      expect(Notify).not_to receive(:organization_activated_email)

      use_event
    end
  end

  context 'when the confirming user no longer exists' do
    before do
      organization.state_metadata['confirmed_by_user_id'] = non_existing_record_id
      organization.organization_detail.save!
    end

    it 'does not send an email' do
      expect(Notify).not_to receive(:organization_activated_email)

      use_event
    end
  end

  context 'when the organization was confirmed by an internal bot' do
    let(:admin_bot) { Users::Internal.in_organization(organization.id).admin_bot }

    before do
      organization.state_metadata['confirmed_by_user_id'] = admin_bot.id
      organization.organization_detail.save!
    end

    it 'does not send an email' do
      expect(Notify).not_to receive(:organization_activated_email)

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
