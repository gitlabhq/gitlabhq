# frozen_string_literal: true

require "spec_helper"

RSpec.describe Integrations::Matrix, feature_category: :integrations do
  it_behaves_like "chat integration", "Matrix", http_method: :put do
    let(:payload) do
      {
        body: be_present,
        msgtype: 'm.notice',
        format: 'org.matrix.custom.html',
        formatted_body: be_present
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
      expect(integration.webhook).to start_with("https://matrix-client.matrix.org/_matrix/client/v3/rooms/#{subject.room}")
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

  describe '#notify' do
    let(:message) { instance_double(Integrations::ChatMessage::PushMessage, summary: '_Test message') }
    let(:header) do
      {
        'Content-Type' => 'application/json',
        'Authorization' => "Bearer #{subject.token}"
      }
    end

    let(:response) { instance_double(HTTParty::Response, success?: true) }
    let(:body) do
      {
        body: '_Test message',
        msgtype: 'm.notice',
        format: 'org.matrix.custom.html',
        formatted_body: Banzai.render_and_post_process('_Test message', context)
      }.compact_blank
    end

    before do
      allow(Gitlab::HTTP).to receive(:put).and_return(response)
    end

    context 'with project-level integration' do
      let(:subject) { create(:matrix_integration) }
      let(:context) { { project: subject.project, no_sourcepos: true } }

      it 'sends PUT request with `project` context' do
        expect(Gitlab::HTTP).to receive(:put).with(anything, headers: header, body: Gitlab::Json.dump(body))

        subject.send(:notify, message, {})
      end
    end

    context 'without project-level integration' do
      let(:subject) { create(:matrix_integration, :instance) }
      let(:context) { { skip_project_check: true, no_sourcepos: true } }

      it 'sends PUT request with `skip_project_check` context' do
        expect(Gitlab::HTTP).to receive(:put).with(anything, headers: header, body: Gitlab::Json.dump(body))

        subject.send(:notify, message, {})
      end
    end
  end
end
