# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ExpiringEmailNotificationWorker, type: :worker, feature_category: :system_access do
  subject(:worker) { described_class.new }

  let_it_be(:member) { create(:project_member, :guest, expires_at: 7.days.from_now.to_date) }
  let_it_be(:notified_member) do
    create(:project_member, :guest, expires_at: 7.days.from_now.to_date, expiry_notified_at: Date.today)
  end

  describe '#perform' do
    context "with not notified member" do
      it "notify member" do
        expect_next_instance_of(NotificationService) do |notification_service|
          expect(notification_service).to receive(:member_about_to_expire).with(member)
        end

        worker.perform(member.id)

        expect(member.reload.expiry_notified_at).to be_present
      end
    end

    context "with notified member" do
      it "not notify member" do
        expect_next_instance_of(NotificationService) do |notification_service|
          expect(notification_service).not_to receive(:member_about_to_expire).with(notified_member)
        end

        worker.perform(notified_member.id)
      end
    end

    context "when feature member_expiring_email_notification is disabled" do
      before do
        stub_feature_flags(member_expiring_email_notification: false)
      end

      it "not notify member" do
        expect_next_instance_of(NotificationService) do |notification_service|
          expect(notification_service).not_to receive(:member_about_to_expire).with(member)
        end

        worker.perform(member.id)
      end
    end
  end
end
