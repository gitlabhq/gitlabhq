# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ErrorTracking::Collector::PayloadValidator do
  let(:validator) { described_class.new }

  describe '#valid?' do
    RSpec.shared_examples 'valid payload' do
      specify do
        expect(validator).to be_valid(payload)
      end
    end

    RSpec.shared_examples 'invalid payload' do
      specify do
        expect(validator).not_to be_valid(payload)
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

    context 'python payload in repl' do
      let(:payload) { Gitlab::Json.parse(fixture_file('error_tracking/python_event_repl.json')) }

      it_behaves_like 'valid payload'
    end

    context 'browser payload' do
      let(:payload) { Gitlab::Json.parse(fixture_file('error_tracking/browser_event.json')) }

      it_behaves_like 'valid payload'
    end

    context 'go payload' do
      let(:payload) { Gitlab::Json.parse(fixture_file('error_tracking/go_parsed_event.json')) }

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
