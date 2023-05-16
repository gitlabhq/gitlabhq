# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GrapeLogging::Loggers::ResponseLogger do
  let(:logger) { described_class.new }

  describe '#parameters' do
    let(:response1) { 'response1' }
    let(:response)  { [response1] }

    subject { logger.parameters(nil, response) }

    it { expect(subject).to eq({ response_bytes: response1.bytesize }) }

    context 'with multiple response parts' do
      let(:response2) { 'response2' }
      let(:response)  { [response1, response2] }

      it { expect(subject).to eq({ response_bytes: response1.bytesize + response2.bytesize }) }
    end

    context 'with log_response_length disabled' do
      before do
        stub_feature_flags(log_response_length: false)
      end

      it { expect(subject).to eq({}) }
    end

    context 'when response is a String' do
      let(:response) { response1 }

      it { expect(subject).to eq({ response_bytes: response1.bytesize }) }
    end
  end
end
