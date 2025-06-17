# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ExpiringWorker, type: :worker, feature_category: :system_access do
  subject(:worker) { described_class.new }

  describe '#perform' do
    let_it_be(:expiring_7_days_project_member) { create(:project_member, :guest, expires_at: 7.days.from_now) }
    let_it_be(:expiring_7_days_group_member) { create(:group_member, :guest, expires_at: 7.days.from_now) }
    let_it_be(:expiring_10_days_project_member) { create(:project_member, :guest, expires_at: 10.days.from_now) }
    let_it_be(:expiring_5_days_project_member) { create(:project_member, :guest, expires_at: 5.days.from_now) }
    let_it_be(:expiring_7_days_requested_project_member) do
      create(:project_member, :guest, :access_request, expires_at: 7.days.from_now)
    end

    let_it_be(:expiring_7_days_invited_project_member) do
      create(:project_member, :guest, :invited, expires_at: 7.days.from_now)
    end

    let(:notify_worker) { Members::ExpiringEmailNotificationWorker }

    it "notifies only active users with membership expiring in less than 7 days" do
      expect(notify_worker).to receive(:perform_async).with(expiring_7_days_project_member.id)
      expect(notify_worker).to receive(:perform_async).with(expiring_7_days_group_member.id)
      expect(notify_worker).to receive(:perform_async).with(expiring_5_days_project_member.id)

      expect(notify_worker).not_to receive(:perform_async).with(expiring_7_days_requested_project_member.id)
      expect(notify_worker).not_to receive(:perform_async).with(expiring_7_days_invited_project_member.id)

      worker.perform
    end
  end
end
