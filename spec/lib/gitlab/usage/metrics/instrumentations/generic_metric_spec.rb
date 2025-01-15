# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::GenericMetric, feature_category: :service_ping do
  shared_examples 'custom fallback' do |custom_fallback|
    subject do
      Class.new(described_class) do
        fallback(custom_fallback)
        value { ApplicationRecord.database.version }
      end.new(time_frame: 'none')
    end

    describe '#value' do
      it 'gives the correct value' do
        expect(subject.value).to eq(ApplicationRecord.database.version)
      end

      context 'when raising an exception' do
        before do
          allow(Gitlab::ErrorTracking).to receive(:should_raise_for_dev?).and_return(should_raise_for_dev)
          expect(ApplicationRecord.database).to receive(:version).and_raise('Error')
        end

        context 'with should_raise_for_dev? false' do
          let(:should_raise_for_dev) { false }

          it 'return the custom fallback' do
            expect(subject.value).to eq(custom_fallback)
          end
        end

        context 'with should_raise_for_dev? true' do
          let(:should_raise_for_dev) { true }

          it 'raises an error' do
            expect { subject.value }.to raise_error('Error')
          end
        end
      end
    end
  end

  context 'with default fallback' do
    subject do
      Class.new(described_class) do
        value { ApplicationRecord.database.version }
      end.new(time_frame: 'none')
    end

    describe '#value' do
      it 'gives the correct value' do
        expect(subject.value).to eq(ApplicationRecord.database.version)
      end

      context 'when raising an exception' do
        before do
          allow(Gitlab::ErrorTracking).to receive(:should_raise_for_dev?).and_return(should_raise_for_dev)
          expect(ApplicationRecord.database).to receive(:version).and_raise('Error')
        end

        context 'with should_raise_for_dev? false' do
          let(:should_raise_for_dev) { false }

          it 'return the default fallback' do
            expect(subject.value).to eq(described_class::FALLBACK)
          end
        end

        context 'with should_raise_for_dev? true' do
          let(:should_raise_for_dev) { true }

          it 'raises an error' do
            expect { subject.value }.to raise_error('Error')
          end
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
