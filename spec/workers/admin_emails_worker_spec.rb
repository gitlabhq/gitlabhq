require 'spec_helper'

describe AdminEmailsWorker do
  context "recipients" do
    let(:recipient_id) { "group-#{group.id}" }
    let(:group) { create :group }

    before do
      2.times do
        group.add_user(create(:user), Gitlab::Access::DEVELOPER)
      end
      unsubscribed_user = create(:user, admin_email_unsubscribed_at: 5.days.ago)
      group.add_user(unsubscribed_user, Gitlab::Access::DEVELOPER)
      ActionMailer::Base.deliveries = []
    end

    it "sends email to subscribed users" do
      perform_enqueued_jobs do
        AdminEmailsWorker.new.perform(recipient_id, 'subject', 'body')
        expect(ActionMailer::Base.deliveries.count).to eql 2
      end
    end
  end
end
