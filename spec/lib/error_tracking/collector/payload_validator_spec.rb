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

    context 'with event fixtures' do
      where(:event_fixture) do
        Dir.glob(Rails.root.join('spec/fixtures/error_tracking/*event*.json'))
      end

      with_them do
        let(:payload) { Gitlab::Json.parse(File.read(event_fixture)) }

        it_behaves_like 'valid payload'
      end
    end

    context 'when empty' do
      let(:payload) { '' }

      it_behaves_like 'invalid payload'
    end

    context 'when invalid' do
      let(:payload) { { 'foo' => 'bar' } }

      it_behaves_like 'invalid payload'
    end
  end
end
