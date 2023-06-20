# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ArchivedAbilities, feature_category: :groups_and_projects do
  let(:test_class) do
    Class.new do
      include ArchivedAbilities
    end
  end

  before do
    stub_const('TestClass', test_class)
  end

  describe '.archived_abilities' do
    it 'returns an array of abilities to be prevented when archived' do
      expect(TestClass.archived_abilities).to include(*described_class::ARCHIVED_ABILITIES)
    end
  end

  describe '.archived_features' do
    it 'returns an array of features to be prevented when archived' do
      expect(TestClass.archived_features).to include(*described_class::ARCHIVED_FEATURES)
    end
  end
end
