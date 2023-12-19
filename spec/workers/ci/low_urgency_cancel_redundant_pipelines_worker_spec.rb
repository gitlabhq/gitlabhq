# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::LowUrgencyCancelRedundantPipelinesWorker, feature_category: :continuous_integration do
  it 'is labeled as low urgency' do
    expect(described_class.get_urgency).to eq(:low)
  end
end
