# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::HarborSerializers::ArtifactSerializer do
  it 'represents Integrations::HarborSerializers::ArtifactEntity entities' do
    expect(described_class.entity_class).to eq(Integrations::HarborSerializers::ArtifactEntity)
  end
end
