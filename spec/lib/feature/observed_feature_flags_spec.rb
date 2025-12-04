# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Observed feature flags', feature_category: :feature_flags do
  before do
    # Reload definitions to clear any stubbed feature flags from other tests
    Feature::Definition.reload!
  end

  it 'limits observed feature flags to a maximum of 10' do
    observed_flags = Feature::Definition.definitions.values.select do |definition|
      definition.attributes[:observed] == true
    end

    expect(observed_flags.count).to be <= Feature::MAX_OBSERVED_FEATURE_FLAGS,
      "Found #{observed_flags.count} observed feature flags, but the maximum allowed is " \
        "#{Feature::MAX_OBSERVED_FEATURE_FLAGS}. Observed flags: #{observed_flags.map(&:name).join(', ')}"
  end
end
