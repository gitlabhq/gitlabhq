# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::Collector::PayloadValidator do
  describe '#valid?' do
    RSpec.shared_examples 'valid payload' do
      it 'returns true' do
        expect(described_class.new.valid?(payload)).to be_truthy
      end
    end

    RSpec.shared_examples 'invalid payload' do
      it 'returns false' do
        expect(described_class.new.valid?(payload)).to be_falsey
      end
    end

    context 'ruby payload' do
      let(:payload) { Gitlab::Json.parse(fixture_file('error_tracking/parsed_event.json')) }

      it_behaves_like 'valid payload'
    end

    context 'python payload' do
      let(:payload) { Gitlab::Json.parse(fixture_file('error_tracking/python_event.json')) }

      it_behaves_like 'valid payload'
    end

    context 'browser payload' do
      let(:payload) { Gitlab::Json.parse(fixture_file('error_tracking/browser_event.json')) }

      it_behaves_like 'valid payload'
    end

    context 'empty payload' do
      let(:payload) { '' }

      it_behaves_like 'invalid payload'
    end

    context 'invalid payload' do
      let(:payload) { { 'foo' => 'bar' } }

      it_behaves_like 'invalid payload'
    end
  end
end
