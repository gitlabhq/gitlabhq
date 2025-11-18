# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Members::ExpiringEmailNotificationWorker, type: :worker, feature_category: :system_access do
  subject(:worker) { described_class.new }

  # expiry_notified_at can leak across specs for this member
  let_it_be_with_reload(:member) { create(:project_member, :guest, expires_at: 7.days.from_now.to_date) }
  let_it_be(:project) { member.source }

  let_it_be(:notified_member) do
    create(:project_member, :guest, expires_at: 7.days.from_now.to_date, expiry_notified_at: Date.today)
  end

  let_it_be(:blocked_member) do
    create(:project_member, :guest, :blocked, expires_at: 7.days.from_now)
  end

  let_it_be(:invited_member) do
    create(:project_member, :guest, :invited, expires_at: 7.days.from_now)
  end

  let_it_be(:project_bot) { create(:user, :project_bot) }
  let_it_be(:bot_member) do
    create(:project_member, :guest, user: project_bot, expires_at: 7.days.from_now)
  end

  before do
    allow(Members::AboutToExpireMailer).to receive(:with).and_call_original
  end

  describe '#perform' do
    context "with not notified member" do
      it "notify member" do
        expect do
          expect(Members::AboutToExpireMailer).to receive(:with).with(member: member)

          worker.perform(member.id)

          expect(member.reload.expiry_notified_at).to be_present
        end.to have_enqueued_mail(Members::AboutToExpireMailer, :email).exactly(:once)
      end

      it 'does not notify blocked member' do
        expect do
          expect(Members::AboutToExpireMailer).not_to receive(:with)

          worker.perform(blocked_member.id)
        end.not_to have_enqueued_mail(Members::AboutToExpireMailer, :email)
      end

      it 'does not notify invited member' do
        expect do
          expect(Members::AboutToExpireMailer).not_to receive(:with)

          worker.perform(invited_member.id)
        end.not_to have_enqueued_mail(Members::AboutToExpireMailer, :email)
      end

      it 'does not notify non-human members' do
        expect do
          expect(Members::AboutToExpireMailer).not_to receive(:with)

          worker.perform(bot_member.id)
        end.not_to have_enqueued_mail(Members::AboutToExpireMailer, :email)
      end
    end

    context "with notified member" do
      it "not notify member" do
        expect do
          expect(Members::AboutToExpireMailer).not_to receive(:with)

          worker.perform(notified_member.id)
        end.not_to have_enqueued_mail(Members::AboutToExpireMailer, :email)
      end
    end
  end

  describe '#valid_for_notification?' do
    subject(:valid_for_notification) { described_class.new.valid_for_notification?(test_member) }

    describe 'with tableized specs' do
      using RSpec::Parameterized::TableSyntax

      where(:test_member, :result) do
        ref(:member)             | true
        ref(:notified_member)    | false
        ref(:blocked_member)     | false
        ref(:invited_member)     | false
        ref(:bot_member)         | false
      end

      with_them do
        it { is_expected.to be result }
      end
    end
  end
end
