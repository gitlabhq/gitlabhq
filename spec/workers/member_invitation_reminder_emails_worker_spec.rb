# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberInvitationReminderEmailsWorker do
  describe '#perform' do
    subject { described_class.new.perform }

    context 'feature flag disabled' do
      before do
        stub_experiment(invitation_reminders: false)
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'feature flag enabled' do
      before do
        stub_experiment(invitation_reminders: true)
      end

      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end
  end
end
