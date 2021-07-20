# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::GenericMetric do
  shared_examples 'custom fallback' do |custom_fallback|
    subject do
      Class.new(described_class) do
        fallback(custom_fallback)
        value { Gitlab::Database.version }
      end.new(time_frame: 'none')
    end

    describe '#value' do
      it 'gives the correct value' do
        expect(subject.value).to eq(Gitlab::Database.version)
      end

      context 'when raising an exception' do
        it 'return the custom fallback' do
          expect(Gitlab::Database).to receive(:version).and_raise('Error')
          expect(subject.value).to eq(custom_fallback)
        end
      end
    end
  end

  context 'with default fallback' do
    subject do
      Class.new(described_class) do
        value { Gitlab::Database.version }
      end.new(time_frame: 'none')
    end

    describe '#value' do
      it 'gives the correct value' do
        expect(subject.value).to eq(Gitlab::Database.version )
      end

      context 'when raising an exception' do
        it 'return the default fallback' do
          expect(Gitlab::Database).to receive(:version).and_raise('Error')
          expect(subject.value).to eq(described_class::FALLBACK)
        end
      end
    end
  end

  context 'with custom fallback -2' do
    it_behaves_like 'custom fallback', -2
  end

  context 'with custom fallback nil' do
    it_behaves_like 'custom fallback', nil
  end

  context 'with custom fallback false' do
    it_behaves_like 'custom fallback', false
  end

  context 'with custom fallback true' do
    it_behaves_like 'custom fallback', true
  end

  context 'with custom fallback []' do
    it_behaves_like 'custom fallback', []
  end

  context 'with custom fallback { major: -1 }' do
    it_behaves_like 'custom fallback', { major: -1 }
  end
end
