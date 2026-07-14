# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mcp::Tools::Concerns::Constants, feature_category: :mcp_server do
  let(:test_class) do
    Class.new do
      include Mcp::Tools::Concerns::Constants
    end
  end

  describe 'GROUP_ONLY_TYPES' do
    it 'contains work item types that can only exist in groups' do
      expect(test_class::GROUP_ONLY_TYPES).to eq(%w[Epic Objective KeyResult])
    end

    it 'is frozen' do
      expect(test_class::GROUP_ONLY_TYPES).to be_frozen
    end
  end

  describe 'PROJECT_AND_GROUP_TYPES' do
    it 'contains work item types that can exist in both projects and groups' do
      expect(test_class::PROJECT_AND_GROUP_TYPES).to eq(%w[Issue Task])
    end

    it 'is frozen' do
      expect(test_class::PROJECT_AND_GROUP_TYPES).to be_frozen
    end
  end

  describe 'ALL_TYPES' do
    it 'contains all work item types' do
      expect(test_class::ALL_TYPES).to match_array(%w[Issue Task Epic Objective KeyResult])
    end

    it 'combines PROJECT_AND_GROUP_TYPES and GROUP_ONLY_TYPES' do
      expected = test_class::PROJECT_AND_GROUP_TYPES + test_class::GROUP_ONLY_TYPES
      expect(test_class::ALL_TYPES).to eq(expected)
    end

    it 'is frozen' do
      expect(test_class::ALL_TYPES).to be_frozen
    end
  end

  describe 'VERSIONS' do
    it 'defines version 0.1.0' do
      expect(test_class::VERSIONS[:v0_1_0]).to eq('0.1.0')
    end

    it 'is frozen' do
      expect(test_class::VERSIONS).to be_frozen
    end

    it 'all version values follow semantic versioning pattern' do
      version_pattern = /\A\d+\.\d+\.\d+\z/

      test_class::VERSIONS.each_value do |version|
        expect(version).to match(version_pattern),
          "Expected version '#{version}' to match semantic versioning pattern (e.g., '1.2.3')"
      end
    end
  end
end
