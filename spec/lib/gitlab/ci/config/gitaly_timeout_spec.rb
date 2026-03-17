# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Ci::Config::GitalyTimeout, feature_category: :pipeline_composition do
  describe '.with_timeout' do
    it 'sets the timeout for the duration of the block' do
      expect(described_class.current_timeout).to be_nil

      described_class.with_timeout(10) do
        expect(described_class.current_timeout).to eq(10)
      end

      expect(described_class.current_timeout).to be_nil
    end

    it 'restores the previous timeout after the block' do
      described_class.with_timeout(5) do
        described_class.with_timeout(10) do
          expect(described_class.current_timeout).to eq(10)
        end

        expect(described_class.current_timeout).to eq(5)
      end

      expect(described_class.current_timeout).to be_nil
    end

    it 'restores the previous timeout even when an exception is raised' do
      expect do
        described_class.with_timeout(10) do
          raise StandardError, 'test error'
        end
      end.to raise_error(StandardError, 'test error')

      expect(described_class.current_timeout).to be_nil
    end

    it 'allows setting timeout to nil' do
      described_class.with_timeout(10) do
        described_class.with_timeout(nil) do
          expect(described_class.current_timeout).to be_nil
        end

        expect(described_class.current_timeout).to eq(10)
      end
    end
  end

  describe '.current_timeout' do
    it 'returns nil when no timeout is set' do
      expect(described_class.current_timeout).to be_nil
    end

    it 'returns the current timeout value when set' do
      described_class.with_timeout(15) do
        expect(described_class.current_timeout).to eq(15)
      end
    end
  end
end
