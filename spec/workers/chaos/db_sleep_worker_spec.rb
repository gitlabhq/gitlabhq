# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Chaos::DbSleepWorker, feature_category: :shared do
  describe '#perform' do
    it 'calls Gitlab::Chaos.db_sleep' do
      expect(Gitlab::Chaos).to receive(:db_sleep).with(5).and_call_original

      described_class.new.perform(5)
    end
  end
end
