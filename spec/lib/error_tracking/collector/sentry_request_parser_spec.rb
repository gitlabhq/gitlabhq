# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::Collector::SentryRequestParser do
  describe '.parse' do
    let_it_be(:raw_event) { fixture_file('error_tracking/event.txt') }
    let_it_be(:parsed_event) { Gitlab::Json.parse(fixture_file('error_tracking/parsed_event.json')) }

    let(:body) { raw_event }
    let(:headers) { { 'Content-Encoding' => '' } }
    let(:request) { double('request', headers: headers, body: StringIO.new(body)) }

    subject { described_class.parse(request) }

    RSpec.shared_examples 'valid parser' do
      it 'returns a valid hash' do
        parsed_request = subject

        expect(parsed_request[:request_type]).to eq('event')
        expect(parsed_request[:event]).to eq(parsed_event)
      end
    end

    context 'empty body content' do
      let(:body) { '' }

      it 'fails with exception' do
        expect { subject }.to raise_error(StandardError)
      end
    end

    context 'plain text sentry request' do
      it_behaves_like 'valid parser'
    end

    context 'gzip encoded sentry request' do
      let(:headers) { { 'Content-Encoding' => 'gzip' } }
      let(:body) { Zlib.gzip(raw_event) }

      it_behaves_like 'valid parser'
    end
  end
end
