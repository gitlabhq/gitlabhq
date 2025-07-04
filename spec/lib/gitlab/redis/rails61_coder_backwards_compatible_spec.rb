# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Rails61CoderBackwardsCompatible, feature_category: :scalability do
  describe '#load' do
    subject(:load) { described_class.load(dumped) }

    context 'with 7.1 cache format' do
      let(:rails_7_1_signature) { "\x00\x11".b }
      let(:dumped) { "#{rails_7_1_signature}some_cached_data" }

      it 'returns nil' do
        expect(load).to be_nil
      end
    end

    context 'with 6.1 format' do
      let(:dumped) do
        "\x04\bo: ActiveSupport::Cache::Entry\t:\x0b@valueI\"\babc\x06:\x06ET:\r@version0:\x10" \
          "@created_atf\x060:\x10@expires_inf\x171750785191.5503879"
      end

      it 'calls Marshal#load' do
        expect(Marshal).to receive(:load)

        load
      end

      it 'returns deserialized value' do
        expect(load.value).to eq('abc')
      end
    end
  end
end
