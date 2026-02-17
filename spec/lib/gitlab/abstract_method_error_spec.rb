# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::AbstractMethodError, feature_category: :tooling do
  it 'can be raised and caught as StandardError' do
    expect { raise described_class }.to raise_error(StandardError, 'Inheriting class must implement this method')
  end

  it 'can be raised with a custom message' do
    expect { raise described_class, 'Custom error message' }.to raise_error(described_class, 'Custom error message')
  end
end
