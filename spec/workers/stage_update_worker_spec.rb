# frozen_string_literal: true

require 'spec_helper'

# This will be removed when we can safely merge the whole removal of StageUpdateWorker.
RSpec.describe StageUpdateWorker, feature_category: :continuous_integration do
  describe '#perform' do
    context 'when stage does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(123) }
          .not_to raise_error
      end
    end
  end
end
