# frozen_string_literal: true

require 'spec_helper'

describe Evidences::EvidenceEntity do
  let(:evidence) { build(:evidence) }
  let(:entity) { described_class.new(evidence) }

  subject { entity.as_json }

  it 'exposes the expected fields' do
    expect(subject.keys).to contain_exactly(:release)
  end
end
