# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Handler::UnsubscribeHandler do
  include_context :email_shared_context

  before do
    stub_incoming_email_setting(enabled: true, address: 'reply+%{key}@appmail.adventuretime.ooo')
    stub_config_setting(host: 'localhost')
  end

  let(:email_raw) { fixture_file('emails/valid_reply.eml').gsub(mail_key, "#{mail_key}#{Gitlab::IncomingEmail::UNSUBSCRIBE_SUFFIX}") }
  let(:project)   { create(:project, :public) }
  let(:user)      { create(:user) }
  let(:noteable)  { create(:issue, project: project) }

  let!(:sent_notification) { SentNotification.record(noteable, user.id, mail_key) }

  context "when email key" do
    let(:mail) { Mail::Message.new(email_raw) }

    it "matches the new format" do
      handler = described_class.new(mail, "#{mail_key}#{Gitlab::IncomingEmail::UNSUBSCRIBE_SUFFIX}")

      expect(handler.can_handle?).to be_truthy
    end

    it "matches the legacy format" do
      handler = described_class.new(mail, "#{mail_key}#{Gitlab::IncomingEmail::UNSUBSCRIBE_SUFFIX_LEGACY}")

      expect(handler.can_handle?).to be_truthy
    end

    it "doesn't match either format" do
      handler = described_class.new(mail, "+#{mail_key}#{Gitlab::IncomingEmail::UNSUBSCRIBE_SUFFIX}")

      expect(handler.can_handle?).to be_falsey
    end
  end

  context 'when notification concerns a commit' do
    let(:commit) { create(:commit, project: project) }
    let!(:sent_notification) { SentNotification.record(commit, user.id, mail_key) }

    it 'handler does not raise an error' do
      expect { receiver.execute }.not_to raise_error
    end
  end

  context 'user is unsubscribed' do
    it 'leaves user unsubscribed' do
      expect { receiver.execute }.not_to change { noteable.subscribed?(user) }.from(false)
    end
  end

  context 'user is subscribed' do
    before do
      noteable.subscribe(user)
    end

    it 'unsubscribes user from notable' do
      expect { receiver.execute }.to change { noteable.subscribed?(user) }.from(true).to(false)
    end

    context 'when using old style unsubscribe link' do
      let(:email_raw) { fixture_file('emails/valid_reply.eml').gsub(mail_key, "#{mail_key}#{Gitlab::IncomingEmail::UNSUBSCRIBE_SUFFIX_LEGACY}") }

      it 'unsubscribes user from notable' do
        expect { receiver.execute }.to change { noteable.subscribed?(user) }.from(true).to(false)
      end
    end
  end

  context 'when the noteable could not be found' do
    before do
      noteable.destroy!
    end

    it 'raises a NoteableNotFoundError' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::NoteableNotFoundError)
    end
  end

  context 'when no sent notification for the mail key could be found' do
    let(:email_raw) { fixture_file('emails/wrong_mail_key.eml') }

    it 'raises a SentNotificationNotFoundError' do
      expect { receiver.execute }.to raise_error(Gitlab::Email::SentNotificationNotFoundError)
    end
  end
end
