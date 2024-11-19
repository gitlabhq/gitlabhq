# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Instrumentation::Middleware::PathTraversalCheck, :request_store, feature_category: :shared do
  describe '.duration' do
    it 'returns the value from Gitlab::SafeRequestStore' do
      expect(Gitlab::SafeRequestStore).to receive(:[]).with(described_class::DURATION_LABEL).and_return(2.3)

      expect(described_class.duration).to eq(2.3)
    end

    it 'returns 0 if the value is not set in Gitlab::SafeRequestStore' do
      expect(Gitlab::SafeRequestStore).to receive(:[]).with(described_class::DURATION_LABEL).and_return(nil)

      expect(described_class.duration).to eq(0)
    end
  end

  describe '.duration=' do
    it 'sets the value' do
      expect { described_class.duration = 0.12345678901 }
        .to change { described_class.duration }.from(0).to(0.123457) # precision is set to 6
    end

    context 'with Gitlab::SafeRequestStore not active' do
      before do
        allow(Gitlab::SafeRequestStore).to receive(:active?).and_return(false)
      end

      it 'does not set the value' do
        expect { described_class.duration = 2.3 }
          .not_to change { described_class.duration }
      end
    end
  end
end
