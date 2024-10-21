# frozen_string_literal: true

# Extracted from https://github.com/googleapis/google-api-ruby-client/blob/main/google-apis-core/spec/google/apis/core/http_command_spec.rb

require 'spec_helper'
require 'google/apis/core/base_service'

RSpec.describe Google::Apis::Core::HttpCommand do # rubocop:disable RSpec/SpecFilePathFormat
  context('with a successful response') do
    let(:client) { Google::Apis::Core::BaseService.new('', '').client }
    let(:command) { described_class.new(:get, 'https://www.googleapis.com/zoo/animals') }

    before do
      stub_request(:get, 'https://www.googleapis.com/zoo/animals').to_return(body: %(Hello world))
    end

    it 'returns the response body if block not present' do
      result = command.execute(client)
      expect(result).to eql 'Hello world'
    end

    it 'calls block if present' do
      expect { |b| command.execute(client, &b) }.to yield_with_args('Hello world', nil)
    end

    it 'retries with max elapsed_time and retries' do
      expect(Retriable).to receive(:retriable).with(
        tries: Google::Apis::RequestOptions.default.retries + 1,
        max_elapsed_time: 900,
        base_interval: 1,
        max_interval: 60,
        multiplier: 2,
        on: described_class::RETRIABLE_ERRORS).and_call_original
      allow(Retriable).to receive(:retriable).and_call_original

      command.execute(client)
    end
  end
end
