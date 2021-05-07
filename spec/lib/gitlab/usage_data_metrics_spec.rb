# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UsageDataMetrics do
  describe '.uncached_data' do
    subject { described_class.uncached_data }

    around do |example|
      described_class.instance_variable_set(:@definitions, nil)
      example.run
      described_class.instance_variable_set(:@definitions, nil)
    end

    before do
      allow(ActiveRecord::Base.connection).to receive(:transaction_open?).and_return(false)
    end

    context 'whith instrumentation_class' do
      it 'includes top level keys' do
        expect(subject).to include(:uuid)
      end
    end
  end
end
