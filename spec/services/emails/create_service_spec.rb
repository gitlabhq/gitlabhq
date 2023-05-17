# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::CreateService, feature_category: :user_management do
  let_it_be(:user) { create(:user) }

  let(:opts) { { email: 'new@email.com', user: user } }

  subject(:service) { described_class.new(user, opts) }

  describe '#execute' do
    it 'creates an email with valid attributes' do
      expect { service.execute }.to change { Email.count }.by(1)
      expect(Email.where(opts)).not_to be_empty
    end

    it 'creates an email with additional attributes' do
      expect { service.execute(confirmation_token: 'abc') }.to change { Email.count }.by(1)
      expect(Email.find_by(opts).confirmation_token).to eq 'abc'
    end

    it 'has the right user association' do
      service.execute

      expect(user.emails).to include(Email.find_by(opts))
    end

    it 'sends a notification to the user' do
      expect_next_instance_of(NotificationService) do |notification_service|
        expect(notification_service).to receive(:new_email_address_added)
      end

      service.execute
    end

    it 'does not send a notification when the email is not persisted' do
      allow_next_instance_of(NotificationService) do |notification_service|
        expect(notification_service).not_to receive(:new_email_address_added)
      end

      service.execute(email: 'invalid@@example.com')
    end

    it 'does not send a notification email when the email is the primary, because we are creating the user' do
      allow_next_instance_of(NotificationService) do |notification_service|
        expect(notification_service).not_to receive(:new_email_address_added)
      end

      # This is here to ensure that the service is actually called.
      allow_next_instance_of(described_class) do |create_service|
        expect(create_service).to receive(:execute).and_call_original
      end

      create(:user)
    end
  end
end
