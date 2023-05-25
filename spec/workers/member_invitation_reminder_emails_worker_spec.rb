# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberInvitationReminderEmailsWorker, feature_category: :groups_and_projects do
  describe '#perform' do
    subject { described_class.new.perform }

    before do
      create(:group_member, :invited, created_at: 2.days.ago)
    end

    it 'executes the invitation reminder email service' do
      expect_next_instance_of(Members::InvitationReminderEmailService) do |service|
        expect(service).to receive(:execute)
      end

      subject
    end
  end
end
