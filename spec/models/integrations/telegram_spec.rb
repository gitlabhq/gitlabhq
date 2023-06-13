# frozen_string_literal: true

require "spec_helper"

RSpec.describe Integrations::Telegram, feature_category: :integrations do
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
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:token) }
      it { is_expected.to validate_presence_of(:room) }
    end

    context 'when integration is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:token) }
      it { is_expected.not_to validate_presence_of(:room) }
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
      let(:integration) { create(:telegram_integration) }

      it 'sets webhook value' do
        expect(integration).to be_valid
        expect(integration.webhook).to eq("https://api.telegram.org/bot123456:ABC-DEF1234/sendMessage")
      end
    end
  end
end
