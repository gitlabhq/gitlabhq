# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Transaction::Settings, feature_category: :database do
  shared_context 'with a CI transaction' do
    before do
      skip_if_shared_database(:ci)
    end

    around do |example|
      Ci::ApplicationRecord.transaction do
        example.run
      end
    end
  end

  describe '#get' do
    before do
      described_class.set('LOCK_TIMEOUT', '200ms')
    end

    it 'gets the value of a configuration' do
      expect(described_class.get('LOCK_TIMEOUT')).to eq('200ms')
    end

    it 'raises an error when config is not allowed' do
      expect { described_class.get('some_config') }.to raise_error(described_class::InvalidConfigError)
    end

    context 'with connection parameter' do
      include_context 'with a CI transaction'

      before do
        described_class.set('LOCK_TIMEOUT', '300ms', Ci::Tag.connection)
      end

      it 'gets the value of a configuration' do
        expect(described_class.get('LOCK_TIMEOUT', Ci::Tag.connection)).to eq('300ms')
      end
    end
  end

  describe '#set' do
    it 'sets a configuration value' do
      described_class.set('LOCK_TIMEOUT', '300ms')

      expect(described_class.get('LOCK_TIMEOUT')).to eq('300ms')
    end

    it 'raises an error when config is not allowed' do
      expect { described_class.set('some_config', 10) }.to raise_error(described_class::InvalidConfigError)
    end

    context 'with connection parameter' do
      include_context 'with a CI transaction'

      it 'sets a configuration value' do
        described_class.set('LOCK_TIMEOUT', '300ms')
        described_class.set('LOCK_TIMEOUT', '400ms', Ci::Tag.connection)

        expect(described_class.get('LOCK_TIMEOUT')).to eq('300ms')
        expect(described_class.get('LOCK_TIMEOUT', Ci::Tag.connection)).to eq('400ms')
      end
    end
  end

  describe '#with' do
    it 'sets a configuration value' do
      described_class.with('LOCK_TIMEOUT', '400ms') do
        expect(described_class.get('LOCK_TIMEOUT')).to eq('400ms')
      end
    end

    it 'restores original configuration value' do
      described_class.set('LOCK_TIMEOUT', '200ms')

      described_class.with('LOCK_TIMEOUT', '500ms') do
        expect(described_class.get('LOCK_TIMEOUT')).to eq('500ms')
      end

      expect(described_class.get('LOCK_TIMEOUT')).to eq('200ms')
    end

    it 'raises an error when config is not allowed' do
      expect do
        described_class.with('some_config', 10) { 1 + 1 }
      end.to raise_error(described_class::InvalidConfigError)
    end

    context 'with connection parameter' do
      include_context 'with a CI transaction'

      it 'sets and restores a configuration value' do
        described_class.set('LOCK_TIMEOUT', '200ms', Ci::Tag.connection)

        described_class.with('LOCK_TIMEOUT', '400ms', Ci::Tag.connection) do
          expect(described_class.get('LOCK_TIMEOUT', Ci::Tag.connection)).to eq('400ms')
        end

        expect(described_class.get('LOCK_TIMEOUT', Ci::Tag.connection)).to eq('200ms')
      end
    end
  end

  describe '#check_allowed!' do
    it 'raises an error when config is not allowed' do
      expect { described_class.check_allowed!('some_config') }.to raise_error(described_class::InvalidConfigError)
    end
  end
end
