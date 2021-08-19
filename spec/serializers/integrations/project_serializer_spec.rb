# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ProjectSerializer do
  it 'represents Integrations::ProjectEntity entities' do
    expect(described_class.entity_class).to eq(Integrations::ProjectEntity)
  end
end
