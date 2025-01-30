# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Handler do
  let(:email) { Mail.new { body 'email' } }

  describe '.for' do
    context 'key matches the reply_key of a notification' do
      it 'picks note handler' do
        expect(described_class.for(email, '1234567890abcdef1234567890abcdef')).to be_an_instance_of(Gitlab::Email::Handler::CreateNoteHandler)
      end
    end

    context 'key matches the reply_key of a notification, along with an unsubscribe suffix' do
      it 'picks unsubscribe handler' do
        expect(described_class.for(email, '1234567890abcdef1234567890abcdef-unsubscribe')).to be_an_instance_of(Gitlab::Email::Handler::UnsubscribeHandler)
      end
    end

    it 'picks issue handler if there is no merge request prefix' do
      expect(described_class.for(email, 'project+key')).to be_an_instance_of(Gitlab::Email::Handler::CreateIssueHandler)
    end

    it 'picks merge request handler if there is merge request key' do
      expect(described_class.for(email, 'project+merge-request+key')).to be_an_instance_of(Gitlab::Email::Handler::CreateMergeRequestHandler)
    end

    it 'returns nil if no handler is found' do
      expect(described_class.for(email, '')).to be_nil
    end

    it 'returns nil if provided email is nil' do
      expect(described_class.for(nil, '')).to be_nil
    end

    context 'new issue email' do
      def handler_for(fixture, mail_key)
        described_class.for(fixture_file(fixture), mail_key)
      end

      before do
        stub_incoming_email_setting(enabled: true, address: "incoming+%{key}@appmail.adventuretime.ooo")
        stub_config_setting(host: 'localhost')
      end

      let!(:user) { create(:user, email: 'jake@adventuretime.ooo', incoming_email_token: 'auth_token') }

      context 'a Service Desk email' do
        it 'uses the Service Desk handler' do
          expect(handler_for('emails/service_desk.eml', 'some/project')).to be_instance_of(Gitlab::Email::Handler::ServiceDeskHandler)
        end
      end

      it 'return new issue handler' do
        expect(handler_for('emails/valid_new_issue.eml', 'some/project+auth_token')).to be_instance_of(Gitlab::Email::Handler::CreateIssueHandler)
      end
    end
  end

  describe 'regexps are set properly' do
    let(:addresses) do
      %W[sent_notification_key#{Gitlab::Email::Common::UNSUBSCRIBE_SUFFIX} sent_notification_key#{Gitlab::Email::Common::UNSUBSCRIBE_SUFFIX_LEGACY}] +
        %w[sent_notification_key path-to-project-123-user_email_token-merge-request] +
        %w[path-to-project-123-user_email_token-issue path-to-project-123-user_email_token-issue-123] +
        %w[path/to/project+user_email_token path/to/project+merge-request+user_email_token some/project]
    end

    before do
      allow(::ServiceDesk).to receive(:supported?).and_return(true)
    end

    it 'picks each handler at least once' do
      matched_handlers = addresses.map do |address|
        described_class.for(email, address).class
      end

      expect(matched_handlers.uniq).to match_array(described_class.handlers)
    end

    it 'can pick exactly one handler for each address' do
      addresses.each do |address|
        matched_handlers = Gitlab::Email::Handler.handlers.select do |handler|
          handler.new(email, address).can_handle?
        end

        expect(matched_handlers.count).to eq(1), "#{address} matches #{matched_handlers.count} handlers: #{matched_handlers}"
      end
    end
  end
end
