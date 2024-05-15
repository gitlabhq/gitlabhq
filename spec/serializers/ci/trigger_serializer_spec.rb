# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::TriggerSerializer, feature_category: :continuous_integration do
  describe '#represent' do
    let(:represent) { described_class.new.represent(trigger) }

    let(:trigger) { build_stubbed(:ci_trigger) }

    it 'matches schema' do
      expect(represent.to_json).to match_schema('entities/trigger')
    end
  end
end
