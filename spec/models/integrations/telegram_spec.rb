# frozen_string_literal: true

require "spec_helper"

RSpec.describe Integrations::Telegram, feature_category: :integrations do
  it_behaves_like Integrations::HasAvatar
  it_behaves_like "chat integration", "Telegram" do
    let(:payload) do
      {
        text: be_present
      }
    end
  end

  describe 'validations' do
    context 'when integration is active' do
      before do
        subject.activate!
      end

      it { is_expected.to validate_presence_of(:token) }
      it { is_expected.to validate_presence_of(:room) }
      it { is_expected.to validate_numericality_of(:thread).only_integer }
    end

    context 'when integration is inactive' do
      before do
        subject.deactivate!
      end

      it { is_expected.not_to validate_presence_of(:token) }
      it { is_expected.not_to validate_presence_of(:room) }
      it { is_expected.not_to validate_numericality_of(:thread).only_integer }
    end
  end

  describe 'before_validation :set_webhook' do
    context 'when token is not present' do
      let(:integration) { build(:telegram_integration, token: nil) }

      it 'does not set webhook value' do
        expect(integration.webhook).to eq(nil)
        expect(integration).not_to be_valid
      end
    end

    context 'when token is present' do
      let(:integration) { build_stubbed(:telegram_integration) }

      it 'sets webhook value' do
        expect(integration).to be_valid
        expect(integration.webhook).to eq("https://api.telegram.org/bot123456:ABC-DEF1234/sendMessage")
      end

      context 'with custom hostname' do
        before do
          integration.hostname = 'https://gitlab.example.com'
        end

        it 'sets webhook value with custom hostname' do
          expect(integration).to be_valid
          expect(integration.webhook).to eq("https://gitlab.example.com/bot123456:ABC-DEF1234/sendMessage")
        end
      end
    end
  end

  describe '#notify' do
    let(:subject) { build(:telegram_integration) }
    let(:message) { instance_double(Integrations::ChatMessage::PushMessage, summary: '_Test message') }
    let(:header) { { 'Content-Type' => 'application/json' } }
    let(:response) { instance_double(HTTParty::Response, bad_request?: true, success?: true) }
    let(:body_1) do
      {
        text: '_Test message',
        chat_id: subject.room,
        message_thread_id: subject.thread,
        parse_mode: 'markdown'
      }.compact_blank
    end

    let(:body_2) { body_1.without(:parse_mode) }

    before do
      allow(Gitlab::HTTP).to receive(:post).and_return(response)
    end

    it 'removes the parse mode if the first request fails with a bad request' do
      expect(Gitlab::HTTP).to receive(:post).with(subject.webhook, headers: header, body: Gitlab::Json.dump(body_1))
      expect(Gitlab::HTTP).to receive(:post).with(subject.webhook, headers: header, body: Gitlab::Json.dump(body_2))

      subject.send(:notify, message, {})
    end

    it 'makes a second request if the first one fails with a bad request' do
      expect(Gitlab::HTTP).to receive(:post).twice

      subject.send(:notify, message, {})
    end
  end
end
