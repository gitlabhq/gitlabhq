# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::CorrelationId do
  describe '.use_id' do
    it 'yields when executed' do
      expect { |blk| described_class.use_id('id', &blk) }.to yield_control
    end

    it 'stacks correlation ids' do
      described_class.use_id('id1') do
        described_class.use_id('id2') do |current_id|
          expect(current_id).to eq('id2')
        end
      end
    end

    it 'for missing correlation id it generates random one' do
      described_class.use_id('id1') do
        described_class.use_id(nil) do |current_id|
          expect(current_id).not_to be_empty
          expect(current_id).not_to eq('id1')
        end
      end
    end
  end

  describe '.current_id' do
    subject { described_class.current_id }

    it 'returns last correlation id' do
      described_class.use_id('id1') do
        described_class.use_id('id2') do
          is_expected.to eq('id2')
        end
      end
    end
  end

  describe '.current_or_new_id' do
    subject { described_class.current_or_new_id }

    context 'when correlation id is set' do
      it 'returns last correlation id' do
        described_class.use_id('id1') do
          is_expected.to eq('id1')
        end
      end
    end

    context 'when correlation id is missing' do
      it 'returns a new correlation id' do
        expect(described_class).to receive(:new_id)
          .and_call_original

        is_expected.not_to be_empty
      end
    end
  end

  describe '.ids' do
    subject { described_class.send(:ids) }

    it 'returns empty list if not correlation is used' do
      is_expected.to be_empty
    end

    it 'returns list if correlation ids are used' do
      described_class.use_id('id1') do
        described_class.use_id('id2') do
          is_expected.to eq(%w(id1 id2))
        end
      end
    end
  end
end
