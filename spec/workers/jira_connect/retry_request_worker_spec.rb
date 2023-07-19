# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnect::RetryRequestWorker, feature_category: :integrations do
  describe '#perform' do
    let(:jwt) { 'some-jwt' }
    let(:event_url) { 'https://example.com/somewhere' }
    let(:attempts) { 3 }

    subject(:perform) { described_class.new.perform(event_url, jwt, attempts) }

    it 'sends the request, with the appropriate headers' do
      expect(described_class).not_to receive(:perform_in)

      stub_request(:post, event_url)

      perform

      expect(WebMock).to have_requested(:post, event_url).with(headers: { 'Authorization' => 'JWT some-jwt' })
    end

    context 'when the proxied request fails' do
      before do
        stub_request(:post, event_url).to_return(status: 500, body: '', headers: {})
      end

      it 'arranges to retry the request' do
        expect(described_class).to receive(:perform_in).with(1.hour, event_url, jwt, attempts - 1)

        perform
      end

      context 'when there are no more attempts left' do
        let(:attempts) { 0 }

        it 'does not retry' do
          expect(described_class).not_to receive(:perform_in)

          perform
        end
      end
    end
  end
end
