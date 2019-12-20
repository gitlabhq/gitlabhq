# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Email::Handler do
  describe '.for' do
    it 'picks issue handler if there is no merge request prefix' do
      expect(described_class.for('email', 'project+key')).to be_an_instance_of(Gitlab::Email::Handler::CreateIssueHandler)
    end

    it 'picks merge request handler if there is merge request key' do
      expect(described_class.for('email', 'project+merge-request+key')).to be_an_instance_of(Gitlab::Email::Handler::CreateMergeRequestHandler)
    end

    it 'returns nil if no handler is found' do
      expect(described_class.for('email', '')).to be_nil
    end
  end

  describe 'regexps are set properly' do
    let(:addresses) do
      %W(sent_notification_key#{Gitlab::IncomingEmail::UNSUBSCRIBE_SUFFIX} sent_notification_key path-to-project-123-user_email_token-merge-request path-to-project-123-user_email_token-issue) +
        %W(sent_notification_key#{Gitlab::IncomingEmail::UNSUBSCRIBE_SUFFIX_LEGACY} sent_notification_key path/to/project+merge-request+user_email_token path/to/project+user_email_token)
    end

    it 'picks each handler at least once' do
      matched_handlers = addresses.map do |address|
        described_class.for('email', address).class
      end

      expect(matched_handlers.uniq).to match_array(ce_handlers)
    end

    it 'can pick exactly one handler for each address' do
      addresses.each do |address|
        matched_handlers = ce_handlers.select do |handler|
          handler.new('email', address).can_handle?
        end

        expect(matched_handlers.count).to eq(1), "#{address} matches #{matched_handlers.count} handlers: #{matched_handlers}"
      end
    end
  end

  def ce_handlers
    @ce_handlers ||= Gitlab::Email::Handler.handlers.reject do |handler|
      handler.name.start_with?('Gitlab::Email::Handler::EE::')
    end
  end
end
