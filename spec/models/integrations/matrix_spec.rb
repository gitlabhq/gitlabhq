# frozen_string_literal: true

require "spec_helper"

RSpec.describe Integrations::Matrix, feature_category: :integrations do
  it_behaves_like "chat integration", "Matrix", http_method: :put do
    let(:payload) do
      {
        body: be_present,
        msgtype: 'm.text',
        format: 'org.matrix.custom.html'
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
      it { is_expected.to validate_presence_of(:webhook) }
    end

    context 'when integration is inactive' do
      before do
        subject.deactivate!
      end

      it { is_expected.not_to validate_presence_of(:token) }
      it { is_expected.not_to validate_presence_of(:room) }
      it { is_expected.not_to validate_presence_of(:webhook) }
    end
  end

  describe 'before_validation :set_webhook' do
    let(:integration) { build_stubbed(:matrix_integration) }

    it 'sets webhook value' do
      expect(integration).to be_valid
      expect(integration.webhook).to start_with('https://matrix.org/_matrix/client/v3/rooms/!qPKKM111FFKKsfoCVy:matrix')
    end

    context 'with custom hostname' do
      before do
        integration.hostname = 'https://gitlab.example.com'
      end

      it 'sets webhook value with custom hostname' do
        expect(integration).to be_valid
        expect(integration.webhook).to start_with("https://gitlab.example.com/_matrix/client/v3/rooms/")
      end
    end
  end
end
