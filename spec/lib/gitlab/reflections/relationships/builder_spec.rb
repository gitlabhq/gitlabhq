# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Reflections::Relationships::Builder, feature_category: :database do
  let(:builder) { described_class.new }

  describe '#build_relationships' do
    it 'returns an array of relationships' do
      relationships = builder.build_relationships

      expect(relationships).to be_an(Array).and all(be_a(Gitlab::Reflections::Relationships::Relationship))
    end
  end
end
