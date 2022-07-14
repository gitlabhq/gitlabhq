# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::HarborSerializers::TagSerializer do
  it 'represents Integrations::HarborSerializers::TagEntity entities' do
    expect(described_class.entity_class).to eq(Integrations::HarborSerializers::TagEntity)
  end
end
