# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::HarborSerializers::RepositorySerializer do
  it 'represents Integrations::HarborSerializers::RepositoryEntity entities' do
    expect(described_class.entity_class).to eq(Integrations::HarborSerializers::RepositoryEntity)
  end
end
