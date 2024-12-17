# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::AdminNotification do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  it 'adds email methods to Notify' do
    subject.instance_methods.each do |email_method|
      expect(Notify).to be_respond_to(email_method)
    end
  end

  describe '#send_admin_notification' do
    subject { Notify.send_admin_notification(recipient.id, 'Subject', 'Body') }

    it 'sends an email' do
      expect(subject).to have_subject 'Subject'
      expect(subject).to have_body_text 'Body'
    end

    it_behaves_like 'an email with suffix'
  end

  describe '#send_unsubscribed_notification' do
    subject { Notify.send_unsubscribed_notification(recipient.id) }

    it 'sends an email' do
      expect(subject).to have_subject 'Unsubscribed from GitLab administrator notifications'
      expect(subject).to have_body_text 'You have been unsubscribed'
    end

    it_behaves_like 'an email with suffix'
  end
end
