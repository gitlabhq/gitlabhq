# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberInvitationReminderEmailsWorker do
  describe '#perform' do
    subject { described_class.new.perform }

    before do
      create(:group_member, :invited, created_at: 2.days.ago)
    end

    context 'feature flag disabled' do
      before do
        stub_experiment(invitation_reminders: false)
      end

      it 'does not attempt to execute the invitation reminder service' do
        expect(Members::InvitationReminderEmailService).not_to receive(:new)

        subject
      end
    end

    context 'feature flag enabled' do
      before do
        stub_experiment(invitation_reminders: true)
      end

      it 'executes the invitation reminder email service' do
        expect_next_instance_of(Members::InvitationReminderEmailService) do |service|
          expect(service).to receive(:execute)
        end

        subject
      end
    end
  end
end
