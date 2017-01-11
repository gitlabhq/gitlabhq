require 'spec_helper'

describe AdminEmailsWorker do
  context "recipients" do
    let(:group) { create :group }
    let(:project) { create :project }

    before do
      2.times do
        user = create(:user)
        group.add_user(user, Gitlab::Access::DEVELOPER)
        project.add_user(user, Gitlab::Access::DEVELOPER)
      end
      unsubscribed_user = create(:user, admin_email_unsubscribed_at: 5.days.ago)
      group.add_user(unsubscribed_user, Gitlab::Access::DEVELOPER)
      project.add_user(unsubscribed_user, Gitlab::Access::DEVELOPER)

      blocked_user = create(:user, state: :blocked)
      group.add_user(blocked_user, Gitlab::Access::DEVELOPER)
      project.add_user(blocked_user, Gitlab::Access::DEVELOPER)
      ActionMailer::Base.deliveries = []
    end

    context "sending emails to members of a group only" do
      let(:recipient_id) { "group-#{group.id}" }

      it "sends email to subscribed users" do
        perform_enqueued_jobs do
          AdminEmailsWorker.new.perform(recipient_id, 'subject', 'body')
          expect(ActionMailer::Base.deliveries.count).to eql 2
        end
      end
    end   

    context "sending emails to members of a project only" do
      let(:recipient_id) { "project-#{project.id}" }

      it "sends email to subscribed users" do
        perform_enqueued_jobs do
          AdminEmailsWorker.new.perform(recipient_id, 'subject', 'body')
          expect(ActionMailer::Base.deliveries.count).to eql 2
        end
      end
    end   

    context "sending emails to users directly" do
      let(:recipient_id) { "all" }

      it "sends email to subscribed users" do
        perform_enqueued_jobs do
          AdminEmailsWorker.new.perform(recipient_id, 'subject', 'body')
          expect(ActionMailer::Base.deliveries.count).to eql 4
        end
      end
    end   
  end
end
