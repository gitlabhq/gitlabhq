# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Evidences::EvidenceSerializer, feature_category: :release_evidence do
  it 'represents an EvidenceEntity entity' do
    expect(described_class.entity_class).to eq(Evidences::EvidenceEntity)
  end
end
