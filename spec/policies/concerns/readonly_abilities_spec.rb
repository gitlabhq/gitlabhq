# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReadonlyAbilities do
  let(:test_class) do
    Class.new do
      include ReadonlyAbilities
    end
  end

  before do
    stub_const('TestClass', test_class)
  end

  describe '.readonly_abilities' do
    it 'returns an array of abilites to be prevented when readonly' do
      expect(TestClass.readonly_abilities).to include(*described_class::READONLY_ABILITIES)
    end
  end

  describe '.readonly_features' do
    it 'returns an array of features to be prevented when readonly' do
      expect(TestClass.readonly_features).to include(*described_class::READONLY_FEATURES)
    end
  end
end
