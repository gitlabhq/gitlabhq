# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Evidences::EvidenceSerializer do
  it 'represents an EvidenceEntity entity' do
    expect(described_class.entity_class).to eq(Evidences::EvidenceEntity)
  end
end
