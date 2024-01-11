# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SlashCommands::VerifyRequest, feature_category: :integrations do
  let_it_be(:integration) { create(:slack_slash_commands_integration) }
  let_it_be(:chat_name) { create(:chat_name) }
  let(:response_url) { 'http://www.example.com/' }

  subject(:verification) { described_class.new(integration, chat_name, response_url) }

  describe '#approve!' do
    before do
      stub_request(:post, "http://www.example.com/").to_return(status: 200, body: 'ok')
    end

    it 'updates the token' do
      expect { verification.approve! }.to change { chat_name.reload.token }.to(integration.token)
    end

    it 'updates the ephemeral message' do
      expect(Gitlab::HTTP).to receive(:post).with(
        response_url, a_hash_including(body: an_instance_of(String), headers: an_instance_of(Hash))
      ).once

      verification.approve!
    end
  end

  describe '#valid?' do
    it 'compares tokens' do
      expect(ActiveSupport::SecurityUtils).to receive(:secure_compare).with(integration.token, chat_name.token)
      verification.valid?
    end
  end
end
