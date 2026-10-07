# frozen_string_literal: true

RSpec.shared_examples 'exposing container expiration policy option' do |model_option|
  it 'exposes all options' do
    expect(described_class.values.keys).to match_array(expected_values)
  end

  it 'uses all possible options from model' do
    all_options = ContainerExpirationPolicy.public_send("#{model_option}_options").keys
    expect(described_class::OPTIONS_MAPPING.keys).to match_array(all_options)
  end
end
